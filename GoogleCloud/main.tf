# Google Cloud

provider "google" {
  credentials = file("/home/mike/credentials/example-251920-d6feefc612ca.json")

  project = "example-251920"
  region  = "us-central1"
  zone    = "us-central1-c"
}


resource "google_compute_network" "vpc_network" {
  name = "terraform-network"
}

# creating rules for firewall. Port 22 open on all hosts, other ports took from map var.role-port 
resource "google_compute_firewall" "vpc_network" {
  for_each = var.role-port
  name    = "${each.key}-firewall"
  network = "${google_compute_network.vpc_network.name}"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  allow {
    protocol = "tcp"
    ports    = var.role-port[each.key]
  }

  target_tags = [ each.key ]
 
}

resource "google_compute_instance" "vm_instance" {
  count = "${length(var.role-port) * var.teamCount}"

  name         = "${keys(var.role-port)[floor(count.index / var.teamCount)]}-${range(var.teamCount)[count.index % var.teamCount]}"
  machine_type = "f1-micro"
  tags	       = ["web", keys(var.role-port)[floor(count.index / var.teamCount)]]

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
    }
  }

  provisioner "local-exec" {
    command = "echo ${self.name}: ${self.network_interface[0].access_config[0].nat_ip}  >> ip-tables.txt"
  }

  provisioner "remote-exec" {
    inline = ["echo Hello, world"]

    connection {
      type        = "ssh"
      user        = "shlepanets"
      private_key = "${file(var.ssh_key_private)}"
      host        = "${self.network_interface[0].access_config[0].nat_ip}"
    }
  }

  provisioner "local-exec" {
    command = "ansible-playbook -u shlepanets -i '${self.network_interface[0].access_config[0].nat_ip},' --private-key ${var.ssh_key_private} --tags ${keys(var.role-port)[floor(count.index / var.teamCount)]} main.yml" 
  }

}
