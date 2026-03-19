#!/usr/bin/env bash
set -euo pipefail

if [ -z "${BASH_VERSION:-}" ]; then
  exec bash "$0" "$@"
fi

WORKDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VM_NAME_DEFAULT="lab1-rocky9-renato-v2"
CONN_DEFAULT="qemu:///session"
POOL_DEFAULT="lab1pool-renato-session-v2"
POOL_PATH_DEFAULT="/tmp/libvirt-lab1-renato-session"
NVRAM_DIR_DEFAULT="/tmp/libvirt-lab1-nvram-renato"
ISO_FILENAME_DEFAULT="Rocky-9.7-x86_64-minimal.iso"

VM_NAME="${VM_NAME:-$VM_NAME_DEFAULT}"
LIBVIRT_CONN="${LIBVIRT_CONN:-$CONN_DEFAULT}"
POOL_NAME="${POOL_NAME:-$POOL_DEFAULT}"
POOL_PATH="${POOL_PATH:-$POOL_PATH_DEFAULT}"
NVRAM_DIR="${NVRAM_DIR:-$NVRAM_DIR_DEFAULT}"
ISO_FILENAME="${ISO_FILENAME:-$ISO_FILENAME_DEFAULT}"
ROCKY_ISO_PATH="${ROCKY_ISO_PATH:-}"

req() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Falta comando requerido: $1"
    exit 1
  fi
}

check_deps() {
  req terraform
  req virsh
}

tf_base_args() {
  echo "-var=libvirt_uri=${LIBVIRT_CONN}"
  echo "-var=vm_name=${VM_NAME}"
  echo "-var=storage_pool=${POOL_NAME}"
  echo "-var=storage_pool_path=${POOL_PATH}"
  echo "-var=vm_nvram_dir=${NVRAM_DIR}"
  echo "-var=iso_filename=${ISO_FILENAME}"

  if [ -n "$ROCKY_ISO_PATH" ]; then
    echo "-var=rocky_iso_path=${ROCKY_ISO_PATH}"
  fi
}

check_iso_source() {
  local repo_iso
  repo_iso="$WORKDIR/iso/$ISO_FILENAME"

  if [ -n "$ROCKY_ISO_PATH" ]; then
    if [ ! -f "$ROCKY_ISO_PATH" ]; then
      echo "No existe ROCKY_ISO_PATH: $ROCKY_ISO_PATH"
      return 1
    fi
    return 0
  fi

  if [ ! -f "$repo_iso" ]; then
    echo "No existe ISO en $repo_iso"
    echo "Copia el ISO a ./iso/$ISO_FILENAME o exporta ROCKY_ISO_PATH=<ruta_absoluta>."
    return 1
  fi
}

domain_in_state() {
  cd "$WORKDIR"
  terraform state list 2>/dev/null | grep -Fxq "libvirt_domain.rocky_vm"
}

domain_uuid_in_conn() {
  virsh -c "$LIBVIRT_CONN" domuuid "$VM_NAME" 2>/dev/null || true
}

import_domain_if_needed() {
  local uuid
  uuid="$(domain_uuid_in_conn)"

  if [ -n "$uuid" ] && ! domain_in_state; then
    echo "Dominio existe fuera del state. Importando UUID: $uuid"
    cd "$WORKDIR"
    # shellcheck disable=SC2086
    terraform import $(tf_base_args) libvirt_domain.rocky_vm "$uuid" || true
  fi
}

check_name_conflict_cross_conn() {
  if [ "$LIBVIRT_CONN" = "qemu:///session" ]; then
    if virsh -c qemu:///system domuuid "$VM_NAME" >/dev/null 2>&1; then
      echo "Conflicto detectado: ya existe '$VM_NAME' en qemu:///system."
      echo "Opciones:"
      echo "1) Eliminar dominio duplicado en system (sudo virsh undefine ...)."
      echo "2) Cambiar vm_name para session."
      return 1
    fi
  fi
  return 0
}

tf_init_validate() {
  cd "$WORKDIR"
  terraform init -input=false
  terraform fmt -recursive
  terraform validate
}

tf_plan() {
  cd "$WORKDIR"
  # shellcheck disable=SC2086
  terraform plan $(tf_base_args)
}

tf_apply() {
  local rc
  local out
  local uuid
  cd "$WORKDIR"
  mkdir -p "$POOL_PATH"
  mkdir -p "$NVRAM_DIR"
  check_iso_source
  check_name_conflict_cross_conn
  import_domain_if_needed
  # shellcheck disable=SC2086
  set +e
  out="$(terraform apply -auto-approve $(tf_base_args) 2>&1)"
  rc=$?
  set -e
  printf '%s\n' "$out"

  if [ "$rc" -ne 0 ]; then
    if printf '%s\n' "$out" | grep -q "Could not open '/home/.*/Descargas/.*\\.iso'.*Permission denied"; then
      echo "Apply fallo por permisos del ISO en /home para qemu:///system."
      echo "Solucion 1 (recomendada): copiar ISO a /var/lib/libvirt/images y actualizar terraform.tfvars."
      echo "Solucion 2: ejecutar runbook con LIBVIRT_CONN=qemu:///session."
      return 1
    fi

    if ! printf '%s\n' "$out" | grep -q "ya existe un dominio"; then
      echo "Apply fallo y no corresponde a conflicto de dominio existente."
      return "$rc"
    fi

    echo "Apply fallo. Intentando auto-reparacion por dominio existente..."

    uuid="$(printf '%s\n' "$out" | sed -n 's/.*uuid \([0-9a-f-]\{36\}\).*/\1/p' | head -n1)"
    if [ -n "$uuid" ] && ! domain_in_state; then
      echo "UUID detectado en error: $uuid"
      cd "$WORKDIR"
      # shellcheck disable=SC2086
      terraform import $(tf_base_args) libvirt_domain.rocky_vm "$uuid" || true
    fi

    import_domain_if_needed
    # shellcheck disable=SC2086
    terraform apply -auto-approve $(tf_base_args)
  fi
}

tf_destroy() {
  cd "$WORKDIR"
  # shellcheck disable=SC2086
  terraform destroy -auto-approve $(tf_base_args) || true
}

vm_status() {
  virsh -c "$LIBVIRT_CONN" list --all
}

vm_start() {
  virsh -c "$LIBVIRT_CONN" start "$VM_NAME" || true
}

vm_shutdown() {
  virsh -c "$LIBVIRT_CONN" shutdown "$VM_NAME" 2>/dev/null || true
}

vm_force_stop() {
  virsh -c "$LIBVIRT_CONN" destroy "$VM_NAME" 2>/dev/null || true
}

vm_undefine() {
  virsh -c "$LIBVIRT_CONN" undefine "$VM_NAME" --nvram 2>/dev/null || true
  virsh -c "$LIBVIRT_CONN" undefine "$VM_NAME" 2>/dev/null || true
}

pool_cleanup() {
  virsh -c "$LIBVIRT_CONN" vol-delete --pool "$POOL_NAME" "${VM_NAME}.qcow2" 2>/dev/null || true
  virsh -c "$LIBVIRT_CONN" pool-destroy "$POOL_NAME" 2>/dev/null || true
  virsh -c "$LIBVIRT_CONN" pool-undefine "$POOL_NAME" 2>/dev/null || true
}

state_cleanup() {
  local r
  cd "$WORKDIR"
  for r in \
    libvirt_domain.rocky_vm \
    libvirt_volume.rocky_iso \
    libvirt_volume.rocky_disk \
    libvirt_pool.vm_pool
  do
    if terraform state list | grep -Fxq "$r"; then
      terraform state rm "$r"
    else
      echo "No existe en state: $r"
    fi
  done
}

open_viewer() {
  if command -v virt-viewer >/dev/null 2>&1; then
    virt-viewer --connect "$LIBVIRT_CONN" "$VM_NAME"
  else
    echo "virt-viewer no esta instalado."
    echo "Instala con: sudo dnf install -y virt-viewer"
    exit 1
  fi
}

show_context() {
  cat <<EOF

Contexto actual:
- WORKDIR: $WORKDIR
- VM_NAME: $VM_NAME
- LIBVIRT_CONN: $LIBVIRT_CONN
- POOL_NAME: $POOL_NAME
- POOL_PATH: $POOL_PATH
- NVRAM_DIR: $NVRAM_DIR
- ISO_FILENAME: $ISO_FILENAME
- ROCKY_ISO_PATH: ${ROCKY_ISO_PATH:-<auto: ./iso/$ISO_FILENAME>}
EOF
}

menu() {
  cat <<'EOF'

==== LAB1 RUNBOOK ====
1) Init + Validate Terraform
2) Plan
3) Apply (Deploy)
4) Estado VM
5) Iniciar VM
6) Abrir visor grafico
7) Apagado limpio VM
8) Apagado forzado VM
9) Limpieza total (destroy + undefine + pool + state)
0) Salir
EOF
}

main() {
  check_deps
  show_context

  while true; do
    menu
    read -r -p "Selecciona opcion: " opt
    case "$opt" in
      1)
        tf_init_validate
        ;;
      2)
        tf_plan
        ;;
      3)
        tf_apply
        ;;
      4)
        vm_status
        ;;
      5)
        vm_start
        ;;
      6)
        open_viewer
        ;;
      7)
        vm_shutdown
        ;;
      8)
        vm_force_stop
        ;;
      9)
        tf_destroy
        vm_force_stop
        vm_undefine
        pool_cleanup
        state_cleanup
        echo "Limpieza total completada."
        ;;
      0)
        echo "Saliendo."
        exit 0
        ;;
      *)
        echo "Opcion invalida"
        ;;
    esac
  done
}

main
