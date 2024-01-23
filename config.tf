terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}


# provider properties
provider "yandex" {
  #my autorization tocken
  token     = "MY_YANDEX_TOKEN"

  #my yandex cloud identifier
  cloud_id  = "b1gogrmv0lhpqnt6hqu1"

  #my yandex folder identifier (default)
  folder_id = "b1g5ks1opqq9pgacsaoo"

  # YANDEX ZONE: ru-central1-a, ru-central1-b, ru-central1-d
  zone = "ru-central1-a"
}




#############################################################
### VM "build"
#############################################################
# vm "build" resource configurations
resource "yandex_compute_instance" "vm-build" {
  name = "build"
  allow_stopping_for_update = true
  resources {
    cores  = 2
    memory = 2
  }
  boot_disk {
    disk_id = yandex_compute_disk.build_ubuntu2004_15GB.id
  }
  network_interface {
    subnet_id = "e9buvssk2htbkq921avo"
    nat       = true
  }
  metadata = {
    user-data = "${file("./public_keys.yml")}"
  }
  scheduling_policy {
    preemptible = true 
  }


  # init vm-build -------------------------
  connection {
    type     = "ssh"
    user     = "spring"
    private_key = file("/root/.ssh/id_rsa")
    host = yandex_compute_instance.vm-build.network_interface.0.nat_ip_address
  }
  provisioner "file" {
    source      = "./Dockerfile"
    destination = "/tmp/Dockerfile"
  }
  # make the artifact, build, tag & push to yeandex registry -------------------------
  provisioner "remote-exec" {
    inline = [
      "sudo apt update", 
      "sudo apt-get update", 
      "sudo apt install mc -y",
      "sudo apt install git -y",
      "sudo apt install docker.io -y",
      "sudo apt install default-jdk -y",
      "sudo apt install maven -y",

      "cd /tmp",
      "git clone https://github.com/boxfuse/boxfuse-sample-java-war-hello.git",

      "cd /tmp/boxfuse-sample-java-war-hello",
      "mvn package",

      "mkdir /tmp/terraform",
      "cp /tmp/boxfuse-sample-java-war-hello/target/hello-1.0.war /tmp/terraform/hello.war",
      "cp /tmp/Dockerfile /tmp/terraform/Dockerfile",
      
      "cd /tmp/terraform",
      "sudo docker build -t mysite1 .",
      "sudo docker tag mysite1 cr.yandex/${yandex_container_registry.my-reg.id}/mysite1",
      "sudo docker push cr.yandex/${yandex_container_registry.my-reg.id}/mysite1"
    ]
  }

}




#############################################################
### VM "prod"
#############################################################
# vm "prod" resource configurations
resource "yandex_compute_instance" "vm-prod" {
  name = "prod"
  allow_stopping_for_update = true
  resources {
    cores  = 2
    memory = 2
  }
  boot_disk {
    disk_id = yandex_compute_disk.prod_ubuntu2004_15GB.id
  }
  network_interface {
    subnet_id = "e9buvssk2htbkq921avo"
    nat       = true
  }
  metadata = {
    user-data = "${file("./public_keys.yml")}"
  }
  scheduling_policy {
    preemptible = true 
  }


  # init vm-prod -------------------------
  connection {
    type     = "ssh"
    user     = "spring"
    private_key = file("/root/.ssh/id_rsa")
    host = yandex_compute_instance.vm-prod.network_interface.0.nat_ip_address
  }
  provisioner "file" {
    source      = "./Dockerfile"
    destination = "/tmp/Dockerfile"
  }
  # pull & run artifact -------------------------
  provisioner "remote-exec" {
    inline = [
      "sudo apt update", 
      "sudo apt-get update", 
      "sudo apt install mc -y",
      "sudo apt install docker.io -y",
      
      "sudo docker pull cr.yandex/${yandex_container_registry.my-reg.id}/mysite1",
      "sudo docker run -d -p 8080:8080 cr.yandex/${yandex_container_registry.my-reg.id}/mysite1"
    ]
  }

  # run after vm-build -------------------------
  depends_on = [
    yandex_compute_instance.vm-build
  ]

}










#############################################################
### VM "zabbix"
#############################################################
# vm "zabbix" resource configurations
resource "yandex_compute_instance" "vm-zabbix" {
  name = "zabbix"
  allow_stopping_for_update = true
  resources {
    cores  = 2
    memory = 2
  }
  boot_disk {
    disk_id = yandex_compute_disk.zabbix_ubuntu2004_15GB.id
  }
  network_interface {
    subnet_id = "e9buvssk2htbkq921avo"
    nat       = true
  }
  metadata = {
    user-data = "${file("./public_keys.yml")}"
  }
  scheduling_policy {
    preemptible = true 
  }


  # init vm-zabbix -------------------------
  connection {
    type     = "ssh"
    user     = "spring"
    private_key = file("/root/.ssh/id_rsa")
    host = yandex_compute_instance.vm-zabbix.network_interface.0.nat_ip_address
  }
  provisioner "file" {
    source      = "./Dockerfile"
    destination = "/tmp/Dockerfile"
  }
  # pull & run artifact -------------------------
  provisioner "remote-exec" {
    inline = [
      "sudo apt update", 
      "sudo apt-get update", 
      "sudo apt install mc -y",
      "sudo apt install docker.io -y",
      
    ]
  }

  # run after vm-prod -------------------------
  depends_on = [
    yandex_compute_instance.vm-prod
  ]

}











#############################################################
### VM DISKS DECLARATION
#############################################################
# boot disk template with ubuntu 20.04
data "yandex_compute_image" "ubuntu_image" {
  family = "ubuntu-2004-lts"
}

# boot disk for vm-build = ubuntu 20.04 with 15GB
resource "yandex_compute_disk" "build_ubuntu2004_15GB" {
  type     = "network-ssd"
  zone     = "ru-central1-a"
  image_id = data.yandex_compute_image.ubuntu_image.id
  size = 15
}
# boot disk for vm-prod = ubuntu 20.04 with 15GB
resource "yandex_compute_disk" "prod_ubuntu2004_15GB" {
  type     = "network-ssd"
  zone     = "ru-central1-a"
  image_id = data.yandex_compute_image.ubuntu_image.id
  size = 15
}




#############################################################
### Yandex Docker Registry: mydockerregistry
#############################################################
resource "yandex_container_registry" "my-reg" {
  name = "mydockerregistry"
  folder_id = "b1g5ks1opqq9pgacsaoo"
  labels = {
    my-label = "it-is-mysite1"
  }
}
resource "yandex_container_registry_iam_binding" "puller" {
  registry_id = yandex_container_registry.my-reg.id
  role        = "container-registry.images.puller"
  members = [
    "system:allUsers",
  ]
}
resource "yandex_container_registry_iam_binding" "pusher" {
  registry_id = yandex_container_registry.my-reg.id
  role        = "container-registry.images.pusher"
  members = [
    "system:allUsers",
  ]
}
