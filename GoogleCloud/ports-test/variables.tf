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
