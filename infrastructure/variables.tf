variable "workshop_network" {
    description = "workshop network name"
}

variable "project" {
  description = "The ID of the Google Cloud project"
}

variable "zone" {
  default = "europe-west1-b"
}

variable "region" {
  default = "europe-west1"
}

variable "machine_type" {
  description = "Google Machine Type to use"
  default     = "g1-small"
}

variable "base_image" {
    description = "Base image to base the workshop image off"
}

variable "credentials_file_path" {
  description = "Path to the JSON file used to describe your account credentials"
  default     = "~/.config/gcloud/accounts.json"
}

variable "user_count" {
    description = "Number of workshop instances to generate"
}

variable "workshop_image" {
    description = "workshop image name"
}

variable "username" {
    description = "Default user to install on workshop instances"
    default = "csuser"
}

variable "passwords" {
    type        = "list"
    description = "List of workshop instances passwords"
}

variable "workshop_names" {
    type        = "list"
    description = "List of workshop instances names"
}
