variable "project" {
  description = "GCP project ID"
  type        = string
  default     = "claude-code-malware"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "asia-northeast3-a"
}

variable "instance_name" {
  description = "VM instance name"
  type        = string
  default     = "win-kics-test-2026"
}

variable "machine_type" {
  description = "GCE machine type"
  type        = string
  default     = "n2-standard-4"
}

variable "use_spot" {
  description = "Use Spot (preemptible) VM to reduce cost"
  type        = bool
  default     = true
}

variable "disk_size_gb" {
  description = "Boot disk size in GB"
  type        = number
  default     = 60
}

variable "winrm_username" {
  description = "Windows user to create for WinRM access"
  type        = string
  default     = "kicstest"
}
