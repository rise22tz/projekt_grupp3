# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "vsphere" {
  user           = var.vsphere_user
  password       = var.vsphere_password
  vsphere_server = var.vsphere_server

  # If you have a self-signed cert
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "datacenter" {
  name = var.datacenter
}

data "vsphere_datastore" "datastore" {
  name          = var.datastore
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_compute_cluster" "cluster" {
  name          = var.cluster
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_network" "network" {
  name          = var.network_name
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_virtual_machine" "ubuntu" {
  name          = "/${var.datacenter}/vm/${var.ubuntu_name}"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

#resource "vsphere_virtual_machine" "test" {
#name             = "terraform-test"
#resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
#datastore_id     = data.vsphere_datastore.datastore.id

#num_cpus = 2
#memory   = 1024

#network_interface {
#network_id = data.vsphere_network.network.id
#}

#wait_for_guest_net_timeout = -1
#wait_for_guest_ip_timeout  = -1

#disk {
#label            = "disk0"
#thin_provisioned = true
#size             = 32
#}

#cdrom {
#client_device = true
#}

#guest_id = "ubuntu64Guest"

#clone {
#template_uuid = data.vsphere_virtual_machine.ubuntu.id
#}
#}

#output "vm_ip" {
#value = vsphere_virtual_machine.test.guest_ip_addresses
#}


resource "vsphere_virtual_machine" "vm" {
  name = "test"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id


disk {
  label            = "disk0"
  thin_provisioned = false
  size             = 32

}

cdrom {
client_device = true
}
network_interface {
  network_id = data.vsphere_network.network.id
}

guest_id = "ubuntu64Guest"

  clone {
    template_uuid = data.vsphere_virtual_machine.ubuntu.id
    customize {

      network_interface {
        ipv4_address = "10.200.50.210"
        ipv4_netmask = 24
      }
      ipv4_gateway = "10.200.50.1"
      dns_server_list = [ "10.200.100.1" ]

      linux_options {
      host_name = "test"
      domain    = "test.local"
      }
    }
  }
}