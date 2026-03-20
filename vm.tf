resource "libvirt_domain" "rocky_vm" {
  name   = var.vm_name
  memory = var.vm_memory_mb
  vcpu   = var.vm_vcpu

  # Configuracion UEFI
  firmware = "/usr/share/edk2/ovmf/OVMF_CODE.fd"

  nvram {
    template = "/usr/share/edk2/ovmf/OVMF_VARS.fd"
    file     = "${var.vm_nvram_dir}/${var.vm_name}_VARS.fd"
  }

  cpu {
    mode = "host-passthrough"
  }

  boot_device {
    dev = ["cdrom", "hd"]
  }

  disk {
    volume_id = libvirt_volume.rocky_disk.id
  }

  # Medio de instalacion
  disk {
    volume_id = libvirt_volume.rocky_iso.id
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type           = "vnc"
    autoport       = true
    listen_type    = "address"
    listen_address = "127.0.0.1"
  }
}
