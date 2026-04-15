terraform {
  required_version = ">= 1.3"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

provider "google" {
  project = var.project
  zone    = var.zone
}

# ── 로컬 값 ────────────────────────────────────────────────────────
locals {
  region = join("-", slice(split("-", var.zone), 0, 2))

  winrm_startup_script = <<-PS1
    winrm quickconfig -force
    winrm set winrm/config '@{MaxEnvelopeSizekb="8192"}'
    winrm set winrm/config/service '@{AllowUnencrypted="true"}'
    winrm set winrm/config/service/auth '@{Basic="true"}'
    Set-Item WSMan:\localhost\Service\AllowUnencrypted $true
    Write-Host "WinRM configured"
  PS1
}

# ── 방화벽: WinRM HTTP (5985) ──────────────────────────────────────
resource "google_compute_firewall" "winrm_http" {
  name    = "allow-winrm-5985"
  network = "default"
  project = var.project

  allow {
    protocol = "tcp"
    ports    = ["5985"]
  }

  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["winrm"]

  lifecycle {
    # 이미 존재하는 경우 충돌 방지
    ignore_changes = [description]
  }
}

# ── 방화벽: WinRM HTTPS (5986) ─────────────────────────────────────
resource "google_compute_firewall" "winrm_https" {
  name    = "allow-winrm-5986"
  network = "default"
  project = var.project

  allow {
    protocol = "tcp"
    ports    = ["5986"]
  }

  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["winrm"]

  lifecycle {
    ignore_changes = [description]
  }
}

# ── Windows Server 2022 VM ────────────────────────────────────────
resource "google_compute_instance" "kics_test" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone
  project      = var.project

  tags = ["winrm"]

  boot_disk {
    initialize_params {
      image = "windows-cloud/windows-2022"
      size  = var.disk_size_gb
      type  = "pd-balanced"
    }
  }

  network_interface {
    network = "default"
    access_config {}   # 외부 IP 할당
  }

  # Spot VM 설정
  scheduling {
    preemptible                 = var.use_spot
    automatic_restart           = var.use_spot ? false : true
    on_host_maintenance         = var.use_spot ? "TERMINATE" : "MIGRATE"
    provisioning_model          = var.use_spot ? "SPOT" : "STANDARD"
    instance_termination_action = var.use_spot ? "STOP" : null
  }

  metadata = {
    windows-startup-script-ps1 = local.winrm_startup_script
  }

  # VM 삭제 시 디스크도 함께 삭제
  allow_stopping_for_update = true
}
