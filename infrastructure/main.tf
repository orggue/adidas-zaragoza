provider "google" {
    project     = "${var.project}"
    region      = "${var.region}"
    credentials = "${file("${var.credentials_file_path}")}"
}

resource "google_compute_network" "default" {
    name        = "${var.workshop_network}"
    auto_create_subnetworks = true
}

resource "google_compute_firewall" "default" {
    name    = "${var.workshop_network}-ssh-access"
    network = "${google_compute_network.default.name}"

    allow {
        protocol        = "tcp"
        ports           = ["80", "22", "8080", "443", "8443", "30000-32767"]
    }

    source_ranges   = ["0.0.0.0/0"]
#    target_tags     = ["workshop-instance"]
}

resource "google_compute_instance" "default" {
    count           = "${var.user_count}"
    machine_type    = "${var.machine_type}"
    name            = "${var.workshop_network}-${var.workshop_names[count.index]}"
    zone            = "${var.zone}"
    tags            = [ "workshop-instance" ]

    disk {
        image = "${var.workshop_image}",
    }

    network_interface {
        network = "${google_compute_network.default.name}"
        access_config {
            // Ephemeral IP
        }
    }

    provisioner "local-exec" {
        command = "echo \"ssh ${var.username}@${self.network_interface.0.access_config.0.assigned_nat_ip} (password: ${var.passwords[count.index]})\" >> .usersfile"
    }

    provisioner "remote-exec" {
        connection {
            type    = "ssh"
            user    = "ubuntu"
            timeout = "120s"
        }

        inline = [
            "sudo useradd -m ${var.username} -G docker,sudo -s /bin/bash -p $(perl -e \"print crypt('${var.passwords[count.index]}','sa');\" 2>/dev/null)",
            "sudo bash -c \"echo '${var.username} ALL=NOPASSWD: ALL' >> /etc/sudoers\""
        ]
    }
}
