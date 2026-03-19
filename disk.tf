resource "libvirt_pool" "vm_pool" {
  name = var.storage_pool
  type = "dir"

  target {
    path = var.storage_pool_path
  }
}

resource "libvirt_volume" "rocky_disk" {
  name   = "${var.vm_name}.qcow2"
  pool   = libvirt_pool.vm_pool.name
  format = "qcow2"
  size   = var.vm_disk_size_bytes
}

resource "libvirt_volume" "rocky_iso" {
  name   = "${var.vm_name}-installer.iso"
  pool   = libvirt_pool.vm_pool.name
  source = local.effective_rocky_iso_path
}
