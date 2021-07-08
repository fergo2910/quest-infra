terraform {
  required_version = "~> 0.14"

  required_providers {
    local  = "~> 2.1.0"
    random = "~> 3.1.0"
    aws    = ">= 3.10"
  }
}