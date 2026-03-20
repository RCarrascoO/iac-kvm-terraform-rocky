variable "libvirt_uri" {
  description = "URI de conexion al hypervisor (por defecto modo usario para evitar sudo)"
  type        = string
  default     = "qemu:///session"
}

variable "vm_name" {
  description = "Nombre de la maquina virtual"
  type        = string
  default     = "lab1-rocky9"
}

variable "vm_memory_mb" {
  description = "Memoria RAM en MB"
  type        = number
  default     = 2048
}

variable "vm_vcpu" {
  description = "Cantidad de vCPU"
  type        = number
  default     = 1
}

variable "vm_disk_size_bytes" {
  description = "Tamano del disco en bytes (24 GiB)"
  type        = number
  default     = 25769803776
}

variable "storage_pool" {
  description = "Nombre del pool de almacenamiento de libvirt"
  type        = string
  default     = "lab1pool"
}

variable "storage_pool_path" {
  description = "Ruta del pool tipo dir para almacenar los discos qcow2"
  type        = string
  default     = "/tmp/libvirt-lab1"
}

variable "vm_nvram_dir" {
  description = "Directorio para archivos NVRAM de la VM (UEFI)."
  type        = string
  default     = "/tmp/libvirt-lab1-nvram"
}

variable "network_name" {
  description = "Red de libvirt para la VM"
  type        = string
  default     = "default"
}

variable "rocky_iso_path" {
  description = "Ruta personalizada de la ISO. Si queda en blanco se busca en ./iso"
  type        = string
  default     = ""
}

variable "iso_filename" {
  description = "Nombre del archivo ISO dentro de la carpeta ./iso del proyecto"
  type        = string
  default     = "Rocky-9.7-x86_64-minimal.iso"
}

variable "institucional_username" {
  description = "Nombre de usuario del estudiante (correo institucional sin el @...)"
  type        = string
}
