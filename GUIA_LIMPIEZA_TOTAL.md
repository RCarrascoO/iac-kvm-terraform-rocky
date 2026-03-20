# Guia de limpieza total del laboratorio

Esta guia deja el entorno en estado limpio para volver a desplegar desde cero, usar si se encuentran errores al intentar realizar un inicio en seco sin limpiar anteriormente con 
##	"terrafom destroy -auto-aprove"

## 1) Detener y eliminar VM en libvirt session

```bash
virsh -c qemu:///session shutdown lab1-rocky9-renato-v2 || true
virsh -c qemu:///session destroy lab1-rocky9-renato-v2 || true
virsh -c qemu:///session undefine lab1-rocky9-renato-v2 --nvram || true
virsh -c qemu:///session undefine lab1-rocky9-renato-v2 || true
```

## 2) Eliminar volumen y pool de almacenamiento usados por session

```bash
virsh -c qemu:///session vol-delete --pool lab1pool-renato-session-v2 lab1-rocky9-renato-v2.qcow2 || true
virsh -c qemu:///session pool-destroy lab1pool-renato-session-v2 || true
virsh -c qemu:///session pool-undefine lab1pool-renato-session-v2 || true
```

## 3) IMPORTANTE: borrar estado local y re-inicializar

```bash
cd /mnt/Files/INF/Sistemas_Proyecto_1
rm -f terraform.tfstate terraform.tfstate.*.backup terraform.tfstate.backup
terraform init -input=false
```

## Limpieza alternativa en qemu:///system

Solo si decidiste trabajar con `qemu:///system` y tienes privilegios sudo:

```bash
sudo virsh -c qemu:///system shutdown lab1-rocky9-renato-v2 || true
sudo virsh -c qemu:///system destroy lab1-rocky9-renato-v2 || true
sudo virsh -c qemu:///system undefine lab1-rocky9-renato-v2 --nvram || true
sudo virsh -c qemu:///system undefine lab1-rocky9-renato-v2 || true
sudo virsh -c qemu:///system pool-destroy lab1pool-renato-session-v2 || true
sudo virsh -c qemu:///system pool-undefine lab1pool-renato-session-v2 || true
```
