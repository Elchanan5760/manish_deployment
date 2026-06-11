terraform {
  required_version = ">= 1.6.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.45"
    }

    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.45"
    }

    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "~> 1.25"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
