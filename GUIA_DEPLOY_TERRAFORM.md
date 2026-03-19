# Guia de deploy con Terraform (enfocada a rubrica)

Esta guia cubre especificamente el despliegue de la VM usando Terraform para evidenciar el punto 2 de la rubrica.

## Objetivo de esta guia

Demostrar, de forma reproducible, que la infraestructura se despliega con Terraform.

## Requisitos previos

1. Tener el proyecto en:

```bash
/mnt/Files/INF/Sistemas_Proyecto_1
```

2. Dejar el ISO dentro de la carpeta `iso/` del proyecto:

```bash
/mnt/Files/INF/Sistemas_Proyecto_1/iso/Rocky-9.7-x86_64-minimal.iso
```

3. Tener Terraform y libvirt operativos.

## Variables esperadas

Revisar [terraform.tfvars](terraform.tfvars) y confirmar al menos:

```hcl
rocky_iso_path         = ""
iso_filename           = "Rocky-9.7-x86_64-minimal.iso"
institucional_username = "renato.carrasco"
libvirt_uri            = "qemu:///session"
storage_pool_path      = "/tmp/libvirt-lab1-renato-session-v2"
storage_pool           = "lab1pool-renato-session-v2"
vm_name                = "lab1-rocky9-renato-v2"
vm_nvram_dir           = "/tmp/libvirt-lab1-nvram-renato-v2"
```

Con esa configuracion, Terraform toma el ISO desde `./iso/<iso_filename>`.

## Deploy paso a paso con Terraform

### 1) Entrar al proyecto

```bash
cd /mnt/Files/INF/Sistemas_Proyecto_1
```

### 2) Inicializar Terraform

```bash
terraform init -input=false
```

### 3) Formatear y validar configuracion

```bash
terraform fmt -recursive
terraform validate
```

### 4) Ver plan de ejecucion

```bash
terraform plan
```

Que debes verificar en el plan:

1. `memory = 2048`
2. `vcpu = 1`
3. volumen de 24 GiB
4. firmware UEFI configurado
5. creacion de dominio, pool y volumen

### 5) Ejecutar deploy

```bash
terraform apply -auto-approve
```

Nota importante sobre tiempos de espera:

- En el primer deploy, Terraform crea `libvirt_volume.rocky_iso` copiando el ISO desde `./iso/` al pool.
- Al usar ahora la versión `minimal.iso`, este paso se completa en unos 10 a 20 segundos y ya no debería quedarse "pegado".

Si aparece este error:

`ya existe un dominio 'lab1-rocky9-renato-v2'`

significa que hay una VM con el mismo nombre en otro contexto de libvirt (normalmente `qemu:///system`).

Verificar:

```bash
virsh -c qemu:///session list --all
virsh -c qemu:///system list --all
```

Resolver (opcion A, recomendada): eliminar dominio duplicado en system:

```bash
sudo virsh -c qemu:///system destroy lab1-rocky9-renato-v2 || true
sudo virsh -c qemu:///system undefine lab1-rocky9-renato-v2 --nvram || true
sudo virsh -c qemu:///system undefine lab1-rocky9-renato-v2 || true
```

Resolver (opcion B): usar otro `vm_name` en `terraform.tfvars`.

Si quedaste en bucle por state desalineado (Terraform dice que existe algo, pero libvirt no):

```bash
cd /mnt/Files/INF/Sistemas_Proyecto_1
terraform state rm libvirt_domain.rocky_vm 2>/dev/null || true
terraform state rm libvirt_volume.rocky_iso 2>/dev/null || true
terraform state rm libvirt_volume.rocky_disk 2>/dev/null || true
terraform state rm libvirt_pool.vm_pool 2>/dev/null || true
terraform init -input=false
terraform plan
```

Luego volver a ejecutar:

```bash
terraform apply -auto-approve
```

Resultado esperado:

- `Apply complete!`
- Recursos creados: pool, volumen y dominio de VM

### 6) Verificar que la VM existe y su estado

```bash
virsh -c qemu:///session list --all
virsh -c qemu:///session dominfo lab1-rocky9-renato-v2
```

En `dominfo` debe verse 1 CPU y memoria 2 GB (2097152 KiB).

## Evidencia recomendada para el video (punto 2 rubrica)

Para demostrar "despliegue de la maquina virtual utilizando Terraform", muestra en este orden:

1. Archivos Terraform del proyecto.
2. `terraform init`
3. `terraform validate`
4. `terraform plan`
5. `terraform apply -auto-approve`
6. `virsh -c qemu:///session list --all`

Con eso queda acreditado que la VM fue desplegada por Terraform.

## Comandos utiles de apoyo

Ver estado Terraform:

```bash
terraform state list
```

Destruir infraestructura (si necesitas repetir deploy):

```bash
terraform destroy -auto-approve
```
