variable "display_name" {
  description = "Display name of the management group."
  type        = string
}

variable "name" {
  description = "Name (ID) of the management group. Null lets Azure generate a UUID."
  type        = string
  default     = null
}

variable "parent_management_group_id" {
  description = "ID of the parent management group. Null places the group under the tenant root group."
  type        = string
  default     = null
}

variable "subscription_ids" {
  description = "Set of subscription IDs to associate with the management group."
  type        = set(string)
  default     = []
}
