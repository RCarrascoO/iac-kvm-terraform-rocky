# Guia de inicio, uso y apagado de la VM

Esta guia corresponde al flujo operativo diario de la VM `lab1-rocky9-renato-v2`.

Modo recomendado para evitar sudo constante: `qemu:///session`.

Si usas el runbook, ejecutar con bash (no con `sudo sh`):

```bash
bash lab1_runbook.sh
```

## 1) Verificar estado de la VM

```bash
virsh -c qemu:///session list --all
```

## 2) Iniciar VM (si esta apagada)

```bash
virsh -c qemu:///session start lab1-rocky9-renato-v2
```

## 3) Abrir consola grafica

```bash
virt-viewer --connect qemu:///session lab1-rocky9-renato-v2
```

Si `virt-viewer` no existe (error 127), instalar:

```bash
sudo dnf install -y virt-viewer
```

Nota: ese `sudo` de instalacion es de una sola vez. La operacion diaria puede quedar sin sudo usando `qemu:///session`.

Alternativa GUI:

```bash
virt-manager
```

### Error comun: Permission denied al abrir ISO en /home

Si usas `qemu:///system` y aparece un error similar a:

`Could not open '/home/.../Descargas/...iso': Permission denied`

puedes resolver de dos formas:

1. Mover/copiar el ISO a una ruta accesible por libvirt system, por ejemplo `/var/lib/libvirt/images/`.
2. Ejecutar en modo sesion de usuario (`qemu:///session`).

## 4) Uso durante instalacion

Dentro del instalador de Rocky Linux 9.x, crear el usuario solicitado:

- usuario: `renato.carrasco`

Luego de instalar y entrar al sistema:

```bash
cat /etc/os-release
```

## 5) Apagar la VM correctamente

### Opcion A (recomendada): desde Rocky Linux

En la VM:

```bash
sudo shutdown -h now
```

### Opcion B: desde el host

Apagado limpio:

```bash
virsh -c qemu:///session shutdown lab1-rocky9-renato-v2
```

Forzado (solo si la VM no responde):

```bash
virsh -c qemu:///session destroy lab1-rocky9-renato-v2
```

## 6) Confirmar que quedo apagada

```bash
virsh -c qemu:///session list --all
```

Debe aparecer con estado `apagado`.

## 7) Reiniciar VM (ciclo rapido)

```bash
virsh -c qemu:///session reboot lab1-rocky9-renato-v2
```

Si no responde al reboot:

```bash
virsh -c qemu:///session destroy lab1-rocky9-renato-v2
virsh -c qemu:///session start lab1-rocky9-renato-v2
```
