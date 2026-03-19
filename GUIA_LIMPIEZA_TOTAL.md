# Guia de limpieza total del laboratorio

Esta guia deja el entorno en estado limpio para volver a desplegar desde cero.

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

## 3) Limpiar state de Terraform

```bash
cd /mnt/Files/INF/Sistemas_Proyecto_1

# Remueve solo recursos que existan en el state para evitar errores ruidosos.
for r in \
	libvirt_domain.rocky_vm \
	libvirt_volume.rocky_disk \
	libvirt_pool.vm_pool \
	libvirt_pool.runtime_pool
do
	if terraform state list | grep -Fxq "$r"; then
		terraform state rm "$r"
	else
		echo "No existe en state: $r"
	fi
done
```

Nota: si en versiones anteriores usaste nombres distintos de recursos, `terraform state rm` podria mostrar
`Invalid target address` o `No matching objects found`. En ese caso no es fallo critico: significa que ese
recurso ya no existe en el state actual.

## 4) Opcional: borrar estado local y re-inicializar

```bash
cd /mnt/Files/INF/Sistemas_Proyecto_1
rm -f terraform.tfstate terraform.tfstate.*.backup terraform.tfstate.backup
terraform init -input=false
```

## 5) Verificacion final de limpieza

```bash
virsh -c qemu:///session list --all
cd /mnt/Files/INF/Sistemas_Proyecto_1 && terraform state list || true
```

Si no aparece la VM y `terraform state list` queda vacio, el entorno esta limpio.

## Limpieza alternativa en qemu:///system

Solo si decidiste trabajar con `qemu:///system` y tienes privilegios sudo:

```bash
sudo virsh -c qemu:///system shutdown lab1-rocky9-renato-v2 || true
sudo virsh -c qemu:///system destroy lab1-rocky9-renato-v2 || true
sudo virsh -c qemu:///system undefine lab1-rocky9-renato-v2 --nvram || true
sudo virsh -c qemu:///system undefine lab1-rocky9-renato-v2 || true
```
