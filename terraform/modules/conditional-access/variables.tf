variable "policy_state" {
  description = "CA policy state: enabled, disabled, enabledForReportingButNotEnforced"
  type        = string
  default     = "enabledForReportingButNotEnforced"
}

variable "break_glass_group_id" {
  description = "Object ID of break-glass accounts group excluded from CA"
  type        = string
}
