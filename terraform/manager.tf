provider "libvirt" {
  uri = "qemu:///system"
}

#provider "libvirt" {
#  alias = "server2"
#  uri   = "qemu+ssh://root@192.168.100.10/system"
#}
data "template_file" "userdata" {
  template = "${file("${path.module}/configs/userconfig_manager.cfg")}"
}

data "template_file" "netdata" {
  template = "${file("${path.module}/configs/netconfig_manager.cfg")}"
}

resource "libvirt_volume" "centos7-qcow2" {
  name = "centos7.qcow2"
  pool = "default"
  source = "https://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2"
  #source = "./CentOS-7-x86_64-GenericCloud.qcow2"
  format = "qcow2"
}

# Define KVM domain to create
resource "libvirt_domain" "db1" {
  name   = "db1"
  memory = "1024"
  vcpu   = 1

  # network_interface {
  #   network_name = "default"
  # }
  network_interface {
    network_name = "10_10_100_network"
    # addresses = ["10.10.100.10/24"]
    # hostname  = "manager"
    # wait_for_lease = true
  }

  disk {
    volume_id = "${libvirt_volume.centos7-qcow2.id}"
  }

  console {
    type = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type = "spice"
    listen_type = "address"
    autoport = true
  }

  cloudinit = "${libvirt_cloudinit_disk.manager-cloudinit.id}"

}

resource "libvirt_cloudinit_disk" "manager-cloudinit" {
  name = "manager-cloudinit.iso"
  #pool = "default"
  user_data = "${data.template_file.userdata.rendered}"
  network_config = "${data.template_file.netdata.rendered}"
}