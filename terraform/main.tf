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

module "vpn" {
  source = "./modules/vpn"
  
  
}