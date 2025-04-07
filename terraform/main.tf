provider "vsphere" {
  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = true


}

data "vsphere_datacenter" "datacenter" {
  # Namnet på datacenter
  name = var.datacenter
}

data "vsphere_datastore" "datastore" {
  # Datastore, skrivs i tfvars
  name          = var.datastore
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_compute_cluster" "cluster" {
  # Namnet på cluster, skrivs i tfvars
  name          = var.cluster
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_virtual_machine" "template" {
  # VM som används som template och blir klonad
  name          = "jammy-server-cloudimg-amd64"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_network" "dmz" {
  name          = "DMZ"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_network" "mgmt" {
  name          = "Management VMs"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

resource "vsphere_folder" "vpn" {
  path          = "VPN"
  type          = "vm"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

resource "vsphere_folder" "runner" {
  path          = "Runners"
  type          = "vm"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

resource "vsphere_folder" "dns" {
  path          = "DNS"
  type          = "vm"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

# VPN
resource "vsphere_virtual_machine" "vpn" {
  count            = 2
  name             = "vpn-${count.index + 1}"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  num_cpus         = 1
  memory           = 1024
  folder           = vsphere_folder.vpn.path
  network_interface {
    network_id = data.vsphere_network.dmz.id
  }
  disk {
    label            = "Hard Disk 1"
    size             = 16
    thin_provisioned = false
  }

  cdrom {
    client_device = true
  }

  vapp {
    properties = {
      "hostname"    = "vpn-${count.index + 1}"
      "public-keys" = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKCnq5ZGGA2Fa17jaWNrBdcvWfhVqUqi6xTksaXJSDvM"
      "instance-id" = "vpn-${count.index + 1}"

    }
  }
  # Måste vara där
  guest_id = "ubuntu64Guest"

  clone {
    # Referens till templaten som deklarerades tidigare
    template_uuid = data.vsphere_virtual_machine.template.id
    customize {

      network_interface {
        ipv4_address = "10.200.200.${count.index + 1}"
        ipv4_netmask = "24"

      }

      ipv4_gateway    = "10.200.200.254"
      dns_server_list = ["10.200.200.254"]
      dns_suffix_list = ["virt.local"]

      linux_options {
        host_name = "vpn-${count.index + 1}"
        domain    = "virt.local"


      }
    }
  }
}

# Runners
resource "vsphere_virtual_machine" "runner" {
  count            = 2
  name             = "runner-${count.index + 1}"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  num_cpus         = 2
  memory           = 2048
  folder           = vsphere_folder.runner.path
  network_interface {
    network_id = data.vsphere_network.mgmt.id
  }
  disk {
    label            = "Hard Disk 1"
    size             = 16
    thin_provisioned = false
  }

  cdrom {
    client_device = true
  }
  vapp {
    properties = {
      "hostname"    = "runner-${count.index + 1}"
      "public-keys" = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKCnq5ZGGA2Fa17jaWNrBdcvWfhVqUqi6xTksaXJSDvM"
      "instance-id" = "runner-${count.index + 1}"
    }
  }

  # Måste vara där
  guest_id = "ubuntu64Guest"

  clone {
    # Referens till templaten som deklarerades tidigare
    template_uuid = data.vsphere_virtual_machine.template.id
    customize {

      network_interface {
        ipv4_address = "10.200.100.5${count.index + 1}"
        ipv4_netmask = "24"

      }

      ipv4_gateway    = "10.200.100.1"
      dns_server_list = ["10.200.100.1"]
      dns_suffix_list = ["virt.local"]

      linux_options {
        host_name = "runner-${count.index + 1}"
        domain    = "virt.local"


      }
    }
  }
}

# Publik DNS
resource "vsphere_virtual_machine" "nameserver" {
  count            = 2
  name             = "ns-${count.index + 1}"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  num_cpus         = 1
  memory           = 1024
  folder           = vsphere_folder.dns.path
  network_interface {
    network_id = data.vsphere_network.dmz.id
  }
  disk {
    label            = "Hard Disk 1"
    size             = 16
    thin_provisioned = false
  }

  cdrom {
    client_device = true
  }
  vapp {
    properties = {
      "hostname"    = "ns-${count.index + 1}"
      "public-keys" = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKCnq5ZGGA2Fa17jaWNrBdcvWfhVqUqi6xTksaXJSDvM"
      "instance-id" = "ns-${count.index + 1}"
    }
  }

  # Måste vara där
  guest_id = "ubuntu64Guest"

  clone {
    # Referens till templaten som deklarerades tidigare
    template_uuid = data.vsphere_virtual_machine.template.id
    customize {

      network_interface {
        ipv4_address = "10.200.200.1${count.index + 1}"
        ipv4_netmask = "24"

      }

      ipv4_gateway    = "10.200.200.254"
      dns_server_list = ["10.200.200.254"]
      dns_suffix_list = ["virt.local"]

      linux_options {
        host_name = "ns-${count.index + 1}"
        domain    = "virt.local"


      }
    }
  }
}
