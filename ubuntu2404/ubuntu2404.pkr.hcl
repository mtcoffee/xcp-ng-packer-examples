packer {
  required_plugins {
   xenserver= {
      version = ">= v0.7.0"
      source = "github.com/ddelnano/xenserver"
    }
  }
}

variable "remote_host" {
  type        = string
  description = "The ip or fqdn of your XCP-ng. It must be the master"
  sensitive   = true
}

variable "remote_username" {
  type        = string
  description = "The username used to interact with your XCP-ng"
  sensitive   = true
}

variable "remote_password" {
  type        = string
  description = "The password used to interact with your XCP-ng"
  sensitive   = true
}

variable "sr_iso_name" {
  type        = string
  description = "The ISO-SR to packer will use"
}

variable "sr_name" {
  type        = string
  description = "The name of the SR to packer will use"
}

variable "iso" {
  type        = string
  description = "The local/http path to your iso"
}

variable "template_name" {
  type        = string
  description = "name of vm and final template"
}

variable "template_description" {
  type        = string
  description = "description of vm and final template"
}

variable "template_cpu" {
  type        = string
  description = "template cpus"
}

variable "template_ram" {
  type        = string
  description = "template ram"
}

variable "template_disk" {
  type        = string
  description = "template disk size"
}

variable "template_networks" {
  type        = list(string)
  description = "list of template network names"
}

variable "template_tags" {
  type        = list(string)
  description = "tags for template"
}

variable "ssh_username" {
  type        = string
  description = "ssh username"
}

variable "ssh_password" {
  type        = string
  description = "ssh pass"
  sensitive   = true
}

source "xenserver-iso" "template" {
  iso_checksum      = "none"
  iso_url = var.iso

  sr_iso_name    = var.sr_iso_name
  sr_name        = var.sr_name
  tools_iso_name = ""

  remote_host     = var.remote_host
  remote_password = var.remote_password
  remote_username = var.remote_username
  
  http_directory = "http"
  http_port_min =  "8078"
  http_port_max =  "8078"
  ip_getter = "tools"

  boot_command = [
    "<esc><esc><esc><esc>e<wait>",
    "<del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del>",
    "<del><del><del><del><del><del><del><del>",
        "linux /casper/vmlinuz --- autoinstall ds=\"nocloud-net;seedfrom=http://{{.HTTPIP}}:{{.HTTPPort}}/\"<enter><wait>",
        "initrd /casper/initrd<enter><wait>",
        "boot<enter>",
        "<enter><f10><wait>"
       ]

  # Change this to match the ISO of ubuntu you are using in the iso_url variable
  clone_template = "Ubuntu Jammy Jellyfish 22.04"
  vm_name        = var.template_name
  vm_description = var.template_description
  vcpus_max	 = var.template_cpu
  vcpus_atstartup = var.template_cpu
  vm_memory      = var.template_ram #MB
  network_names = var.template_networks
  disk_size      = var.template_disk #MB
  disk_name      = "${var.template_name}-disk"
  vm_tags        = var.template_tags
  
  ssh_username            = var.ssh_username
  ssh_password            = var.ssh_password
  ssh_wait_timeout        = "90s"
  ssh_handshake_attempts  = 1000
  #shutdown_command        = "sudo bash -c 'sleep 10s && shutdown -h now'"


  output_directory = "packer-ubuntu"
  keep_vm          = "on_success"
  format = "none"
}

build {
  sources = ["xenserver-iso.template"]
  
  provisioner "shell" {
      remote_folder = "~"
      inline = ["while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 5; done"]
  }

  provisioner "shell" {
    remote_folder      = "~"
    inline = ["sudo cloud-init clean"]
  }

  provisioner "shell" {
    remote_folder      = "~"
    inline = ["sudo truncate -s 0 /etc/machine-id /var/lib/dbus/machine-id"]
  }
}




