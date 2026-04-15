output "instance_name" {
  description = "VM 인스턴스 이름"
  value       = google_compute_instance.kics_test.name
}

output "external_ip" {
  description = "VM 외부 IP 주소"
  value       = google_compute_instance.kics_test.network_interface[0].access_config[0].nat_ip
}

output "zone" {
  description = "VM 존"
  value       = google_compute_instance.kics_test.zone
}

output "get_password_command" {
  description = "Windows 비밀번호 획득 명령어 (VM 부팅 후 2~3분 후 실행)"
  value = format(
    "gcloud compute reset-windows-password %s --project=%s --zone=%s --user=%s --quiet",
    google_compute_instance.kics_test.name,
    var.project,
    google_compute_instance.kics_test.zone,
    var.winrm_username,
  )
}

output "run_diagnostics_command" {
  description = "진단 실행 명령어 (비밀번호 획득 후 사용)"
  value       = "python3 run_remote_test.py --ip <external_ip> --user ${var.winrm_username} --pass <password>"
}

output "run_diagnostics_with_setup_command" {
  description = "서비스 환경 구성 + 진단 실행 (FTP/DNS/SNMP 포함)"
  value       = "python3 run_remote_test.py --ip <external_ip> --user ${var.winrm_username} --pass <password> --setup"
}
