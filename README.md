# Laboratorio 1 - Terraform + QEMU/KVM (Rocky Linux 9.x)

Proyecto de despliegue automatizado de Infraestructura como Código (IaC), ejecutado en Fedora 43 con Terraform y libvirt.

## Objetivo

Desplegar una VM con los siguientes requerimientos:

- SO: Rocky Linux 9.x
- RAM: 2 GB
- CPU: 1 vCPU
- Disco: 24 GB
- Firmware: UEFI
- Virtualizacion: QEMU/KVM
- Automatizacion: Terraform

## Estado actual del laboratorio

- VM objetivo: `lab1-rocky9-renato-v2`
- Usuario configurado en el sistema: `renato.carrasco`
- ISO usada: `./iso/Rocky-9.7-x86_64-minimal.iso` (relativa a la raiz del proyecto)
- Despliegue probado y funcional por `qemu:///session` con socket de sesion.

## Estructura del proyecto

- main.tf
- variables.tf
- disk.tf
- vm.tf
- terraform.tfvars.example
- README.md
- GUIA_LIMPIEZA_TOTAL.md
- GUIA_INICIO_APAGADO_VM.md

## Proceso de despliegue

1. Configuracion base de Terraform con provider libvirt y definición de recursos.
2. Parametrizacion de recursos de infraestructura: 2 GB RAM, 1 vCPU, 24 GB de disco y arranque UEFI.
3. Incorporacion de variables para Rocky Linux ISO y gestion de usuarios. 
# Esto se realiza durante la instalacion 
4. Validacion de sintaxis mediante `terraform fmt` y `terraform validate`.
5. Ejecucion del despliegue con los comandos `terraform plan` y `terraform apply`.
6. Ajuste en la salida grafica utilizando VNC para compatibilidad local con QEMU.
7. Verificacion de la instancia con `virsh` (revision de carga de vCPU y memoria).
8. Acceso a la instalacion de Rocky via consola grafica.
9. Reemplazo de ISO en formato DVD a la version Minimal (1.5GB) para optimizar los tiempos de provisionamiento.

## Problemas encontrados y soluciones aplicadas

1. Error de autenticacion con `qemu:///system`:

- Causa: permisos/politica de acceso a libvirt sin sudo interactivo.
- Solucion aplicada: despliegue operativo por `qemu:///session` usando socket de sesion.

2. Conflictos por dominios/pools previos:

- Causa: recursos residuales de pruebas anteriores.
- Solucion aplicada: limpieza de state y redefinicion controlada de recursos.

3. Error SPICE no soportado:

- Causa: binario QEMU del host sin soporte SPICE.
- Solucion aplicada: uso de `graphics` tipo VNC.

4. Error UEFI (master var store/loader):

- Causa: firmware UEFI no definido correctamente en el dominio.
- Solucion aplicada: firmware explicito con OVMF y bloque `nvram`.

5. Tiempos de despliegue excesivos (Terraform colgado copiando ISO):

- Causa: ISO completa pesaba 13GB tardando varios minutos en local.
- Solucion aplicada: cambio a Rocky Linux Minimal ISO (1.5GB) reduciendo el tiempo a 10 segundos.

6. Error 127 al abrir visor grafico:

- Causa: `virt-viewer` no instalado en algunos intentos.
- Solucion aplicada: documentado `sudo dnf install -y virt-viewer` y alternativa `virt-manager`.

7. Error de Storage Pool ('already exists'):

- Causa: Terraform pierde el estado pero libvirt mantiene registrado en el host (`qemu:///system`) un disco o pool de nombre idéntico de anteriores pruebas interrumpiendo el despliegue de root a user (`session`).
- Solucion aplicada: Ejecutar limpieza forzada directa en libvirt del sistema subyacente usando `sudo virsh -c qemu:///system pool-destroy ...` (documentado en guías).

## Como iniciar, usar y apagar la VM (guia operativa)

Ver guia completa en `GUIA_INICIO_APAGADO_VM.md`.

Resumen rapido:

```bash
virsh -c qemu:///session list --all
virsh -c qemu:///session start lab1-rocky9-renato-v2
virt-viewer --connect qemu:///session lab1-rocky9-renato-v2
```

Apagado recomendado desde la VM:

```bash
sudo shutdown -h now
```

Apagado desde host:

```bash
virsh -c qemu:///session shutdown lab1-rocky9-renato-v2
```

## Script de pruebas rapidas (runbook)

Se agrego un script interactivo para facilitar pruebas locales:

- `lab1_runbook.sh`

Ejecutar:

```bash
cd /mnt/Files/INF/Sistemas_Proyecto_1
bash lab1_runbook.sh
```

Recomendacion:

- Evitar `sudo sh lab1_runbook.sh`.
- Usar `bash lab1_runbook.sh` en modo `qemu:///session` para minimizar uso de sudo.

El menu permite:

1. Inicializar y validar Terraform.
2. Plan y apply de despliegue.
3. Ver estado, iniciar y apagar VM.
4. Abrir visor grafico.
5. Limpieza total del laboratorio.

## Limpieza total del entorno

Ver guia completa en `GUIA_LIMPIEZA_TOTAL.md`.

## Guia de despliegue con Terraform

Para ver el paso a paso de construccion de los recursos, usar:

- `GUIA_DEPLOY_TERRAFORM.md`

## Chequeo inicial post-instalacion

Durante instalacion crear usuario:

- `renato.carrasco`

Luego de iniciar sesion en Rocky:

```bash
cat /etc/os-release
```

Debe mostrar Rocky Linux 9.x.

## Empaquetado del proyecto

```bash
tar -czvf nombre-apellido-lab1.tar.gz Sistemas_Proyecto_1
```

## Notas de reproducibilidad

- Si usas `qemu:///system`, puede requerir sudo para comandos Terraform/virsh.
- Si usas `qemu:///session`, usar visor con `--connect qemu:///session`.
- Mantener `terraform.tfvars` coherente con el modo de conexion elegido.
- Para evitar rutas personales, dejar el ISO dentro de `./iso/` del proyecto.
