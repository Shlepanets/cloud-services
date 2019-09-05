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

resource "google_compute_firewall" "vpc_network" {
  name    = "test-firewall"
  network = "${google_compute_network.vpc_network.name}"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

}

resource "google_compute_address" "vm_static_ip" {
  name = "terraform-static-ip"
}

resource "google_compute_instance" "vm_instance" {
  name         = "terraform-instance"
  machine_type = "f1-micro"
  tags	       = ["web", "test"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.self_link
    access_config {
      nat_ip = google_compute_address.vm_static_ip.address
    }
  }

  provisioner "local-exec" {
    command = "echo ${google_compute_instance.vm_instance.name}:  ${google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip} >> ip_address.txt"
  }

  provisioner "local-exec" {
    command = "echo ${google_compute_instance.vm_instance.name}:  ${google_compute_address.vm_static_ip.address} >> ip_address.txt"
  }

  provisioner "remote-exec" {
    inline = ["sudo touch in-test.ll"]

    connection {
      type        = "ssh"
      user        = "shlepanets"
      private_key = "${file(var.ssh_key_private)}"
      host        = "${google_compute_address.vm_static_ip.address}"
    }
  }

  provisioner "local-exec" {
    command = "ansible-playbook -u shlepanets -i '${google_compute_address.vm_static_ip.address},' --private-key ${var.ssh_key_private} main.yml" 
  }

}
