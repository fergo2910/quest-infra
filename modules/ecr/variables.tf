variable "create_repos" {
  type        = bool
  description = "Boolean that controls if the repo is created or not, depending on the environment"
}

variable "tags" {
  description = "A map of tags to assign to the registry"
  type        = map(string)
  default     = {}
}

variable "resource_based_policy" {
  description = "True if we want to attach a resource-based policy allowing push/pull actions"
  default     = true
}

variable "allowed_account_ids" {
  description = "A list of AWS Account IDs to give access to pull/push images from/to the repo"
  type        = list(string)
  default     = []
}

variable "repos" {
  default     = []
  description = "The list of repos to allocate."
  type        = list(object({ name = string, mutable = bool, image_scan = bool }))
}