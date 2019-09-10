variable "ssh_key_public" {
	default		= "~/.ssh/gce_rsa.pub"
	description	= "Path to the SSH public key for accessing cloud instances."
}

variable "ssh_key_private" {
	default		= "~/.ssh/gce_rsa"
	description	= "Path to the SSH private key for accessing cloud instances."
}

variable "role-port" {
    type = map
    default = {
      test = [ "80", "443"]
      test2 = [ "81", "443"]
    }
}

variable "teamCount" { 
  default = 2 
}


