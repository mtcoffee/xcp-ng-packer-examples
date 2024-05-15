packer {
  required_plugins {
   xenserver= {
      version = ">= v0.7.0"
      source = "github.com/ddelnano/xenserver"
    }
    windows-update = {
      version = "0.15.0"
      source = "github.com/rgl/windows-update"
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


variable "winrm_username" {
  type        = string
  description = "winrm username"
}

variable "winrm_password" {
  type        = string
  description = "winrm pass"
  sensitive   = true
}

source "xenserver-iso" "win2022" {
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

  boot_wait = "1s"
  boot_command = [
    "a<wait>a<wait>a",
       ]
	   
  floppy_files = [
    "setup/autounattend.xml",
	"setup/presetup.cmd",
    "setup/setup.ps1"
      ]
	  
  platform_args = {
    viridian        = true
    nx              = true
    pae             = true
    apic            = true
    timeoffset      = 0
    acpi            = true
    cores-per-socket = 1
  }


  # Change this to match the ISO of ubuntu you are using in the iso_url variable
  clone_template = "Windows Server 2022 (64-bit)"
  firmware       = "bios" #autounattend.xml floppy_files not working in uefi
  vm_name        = var.template_name
  vm_description = var.template_description
  vcpus_max	 = var.template_cpu
  vcpus_atstartup = var.template_cpu
  vm_memory      = var.template_ram #MB
  network_names = var.template_networks
  disk_size      = var.template_disk #MB
  disk_name      = "${var.template_name}-disk"
  vm_tags        = var.template_tags
  
  communicator              = "winrm"
  ssh_username            = "N/A"  #this is hard coded into the packer plugin so it must be set to anything
  winrm_username            = var.winrm_username
  winrm_password            = var.winrm_password



  output_directory = "packer-win2022"
  keep_vm          = "on_success"
  format = "none"
}

build {
  sources = ["xenserver-iso.win2022"]
  
  provisioner "windows-shell" {
      inline = ["dir c:\\"]
  }
   provisioner "windows-update" {

  }

}




