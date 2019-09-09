# Google Cloud

variable "roles" {
  type	= list(string)
  description = "roles to be executed on target hosts"
  default = [ "test", "test2" ]
}

variable "instances" {
  type	= list(string)
  description = "VM id's"
  default = [ "1", "2" ]
}


provider "google" {
  credentials = file("/home/mike/credentials/example-251920-d6feefc612ca.json")

  project = "example-251920"
  region  = "us-central1"
  zone    = "us-central1-c"
}

resource "google_compute_network" "vpc_network" {
  name = "terraform-network"
}

resource "google_compute_firewall" "vpc_network" {
  name    = "test-firewall"
  network = "${google_compute_network.vpc_network.name}"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

#resource "google_compute_address" "vm_static_ip" {
#  count = 3
#  name = "terraform-static-ip-${count.index}"
#}

resource "google_compute_instance" "vm_instance" {
  count = "${length(var.roles) * length(var.instances)}"

  name         = "instance-${var.roles[floor(count.index / length(var.instances))]}-${var.instances[count.index % length(var.instances)]}"
  machine_type = "f1-micro"
  tags	       = ["web", "test"]

  boot_disk {
    initialize_params {
      image = "centos-7-v20190813"
    }
  }
  
  metadata = {
    ssh-keys = "shlepanets:${file(var.ssh_key_public)}"
  }

  network_interface {
    network = google_compute_network.vpc_network.self_link
    access_config {
#      nat_ip = google_compute_address.vm_static_ip[count.index].address
    }
  }

  provisioner "local-exec" {
    command = "echo ${self.name}: ${self.network_interface[0].access_config[0].nat_ip}  >> ip-tables.txt"
  }
#
#  provisioner "local-exec" {
#    command = "echo ${google_compute_instance.vm_instance.name}:  ${google_compute_address.vm_static_ip.address}"
#  }
#
  provisioner "remote-exec" {
    inline = ["sudo touch in-test.ll"]

    connection {
      type        = "ssh"
      user        = "shlepanets"
      private_key = "${file(var.ssh_key_private)}"
      host        = "${self.network_interface[0].access_config[0].nat_ip}"
    }
  }

  provisioner "local-exec" {
    command = "ansible-playbook -u shlepanets -i '${self.network_interface[0].access_config[0].nat_ip},' --private-key ${var.ssh_key_private} --tags ${var.roles[floor(count.index / length(var.instances))]} main.yml" 
  }

}
