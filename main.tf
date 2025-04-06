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
  name          = var.ubuntu_name
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_network" "network" {
  # Nätverk för VM, skrivs i tfvars
  name          = var.network_name
  datacenter_id = data.vsphere_datacenter.datacenter.id
}


resource "vsphere_virtual_machine" "vm" {
  name             = "terraform-test"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  num_cpus         = 1
  memory           = 1024
  network_interface {
    network_id = data.vsphere_network.network.id
  }
  disk {
    label            = "Hard Disk 1"
    size             = 16
    thin_provisioned = true
  }

  cdrom {
    client_device = true
  }

  # Måste vara där
  guest_id = "ubuntu64Guest"

  clone {
    # Referens till templaten som deklarerades tidigare
    template_uuid = data.vsphere_virtual_machine.template.id
    customize {

      network_interface {
        ipv4_address = "10.200.50.220"
        ipv4_netmask = "24"

      }

      ipv4_gateway    = "10.200.50.1"
      dns_server_list = ["10.200.50.1"]
      dns_suffix_list = ["virt.local"]

      linux_options {
        host_name = "test"
        domain    = "virt.local"

      }
    }
  }
}
