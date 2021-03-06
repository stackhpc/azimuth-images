# Use like:
#  $ PACKER_LOG=1 packer build --on-error=ask -var-file=<something>.pkrvars.hcl openstack.pkr.hcl

# "timestamp" template function replacement:s
locals { timestamp = formatdate("YYMMDD-hhmm", timestamp())}

variable "source_image_name" {
  type = string
}

variable "network" {
  type = string
}

variable "floating_ip_network" {
  type = string
}

variable "flavor" {
  type = string
}

variable "security_groups" {
  type = list(string)
}

variable "volume_size" {
  type = number
  default = 5
}

variable "disk_format" {
  type = string
}

variable "distro_name" {
  type = string
}

variable "ssh_username" {
  type = string
}

source "openstack" "jupyter-repo2docker" {
  image_name = "${var.distro_name}-jupyter-repo2docker-${local.timestamp}"
  image_visibility = "private"
  image_disk_format = "${var.disk_format}"
  image_min_disk = "${var.volume_size}"

  source_image_name = "${var.source_image_name}"
  flavor = "${var.flavor}"
  networks = ["${var.network}"]
  security_groups = "${var.security_groups}"
  floating_ip_network = "${var.floating_ip_network}"

  # In order to be able to specify an image disk format, we must be using a Cinder volume
  use_blockstorage_volume = true
  volume_size = "${var.volume_size}"

  communicator = "ssh"
  ssh_username = "${var.ssh_username}"
  ssh_clear_authorized_keys = true
}

build {
  source "source.openstack.jupyter-repo2docker" { }

  provisioner "ansible" {
    galaxy_file = "${path.root}/../requirements.yml"
    playbook_file = "${path.root}/../ansible/jupyter-repo2docker.yml"
    use_proxy = false
    extra_arguments = ["-v"]
  }

  post-processor "manifest" {
    custom_data = {
      source = "${source.name}"
    }
  }
}
