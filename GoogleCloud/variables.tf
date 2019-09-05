variable "ssh_key_public" {
	default		= "~/.ssh/gce_rsa.pub"
	description	= "Path to the SSH public key for accessing cloud instances."
}

variable "ssh_key_private" {
	default		= "~/.ssh/gce_rsa"
	description	= "Path to the SSH private key for accessing cloud instances."
}


