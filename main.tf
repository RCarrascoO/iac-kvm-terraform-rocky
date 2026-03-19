terraform {
  required_version = ">= 1.5.0"

  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.8.3"
    }
  }
}

provider "libvirt" {
  uri = var.libvirt_uri
}

locals {
  effective_rocky_iso_path = trimspace(var.rocky_iso_path) != "" ? var.rocky_iso_path : "${path.module}/iso/${var.iso_filename}"
}
