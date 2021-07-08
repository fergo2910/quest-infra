terraform {
  required_version = "~> 0.14"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.10.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 1.3.2"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 1.13.2"
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.7.0"
    }

    template = {
      source  = "hashicorp/template"
      version = "~> 2.2.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 3.0.0"
    }
  }
}
