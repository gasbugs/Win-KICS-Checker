#!/usr/bin/env python3
"""
Win-KICS-Checker 2026 — Remote Test Runner
Copies scripts_2026/ to Windows VM via WinRM and executes the diagnostic suite.

Usage:
  python3 run_remote_test.py [--ip IP] [--user USER] [--pass PASS] [--setup]

  --setup   서비스 환경 구성 후 진단 (FTP/DNS/SNMP 설치)
"""
import os
import sys
import time
import base64
import json
import argparse
import winrm
import warnings
warnings.filterwarnings("ignore")

DEFAULT_IP   = "34.22.96.68"
DEFAULT_USER = "kicstest"
DEFAULT_PASS = "k$CKm/+1&<Jc>(6"
REMOTE_ROOT  = r"C:\kics2026"
LOCAL_ROOT   = os.path.dirname(os.path.abspath(__file__))

# Exit code from setup_services_2026.ps1 when restart is needed
RESTART_NEEDED_EXIT = 1001


def make_session(ip, user, password):
    # Try HTTPS (5986) first; fall back to HTTP (5985) if needed
    return winrm.Session(
        f"https://{ip}:5986/wsman",
        auth=(user, password),
        transport="ntlm",
        server_cert_validation="ignore",
        read_timeout_sec=300,
        operation_timeout_sec=290,
    )


def run_ps(session, script, label=""):
    """Run a PowerShell snippet and return (stdout, stderr, rc)."""
    r = session.run_ps(script)
    stdout = r.std_out.decode("utf-8", errors="replace").strip()
    stderr = r.std_err.decode("utf-8", errors="replace").strip()
    if label:
        print(f"[{label}] rc={r.status_code}")
        if stdout:
            print(stdout[:2000])
        if stderr:
            print(f"  STDERR: {stderr[:500]}")
    return stdout, stderr, r.status_code


def upload_file_via_stdin(protocol, shell_id, local_path, remote_path):
    """
    Upload a file using batched echo→certutil decode approach.
    Writes base64 lines (76 chars each) in cmd.exe batches (~60 lines/batch),
    then runs certutil -decode. No command-line length limits.
    """
    with open(local_path, "rb") as f:
        raw = f.read()

    # Add UTF-8 BOM so PowerShell 5.x reads Korean/non-ASCII text correctly
    UTF8_BOM = b"\xef\xbb\xbf"
    if not raw.startswith(UTF8_BOM):
        raw = UTF8_BOM + raw

    remote_dir = "\\".join(remote_path.split("\\")[:-1])
    tmp_b64 = r"C:\kics2026\_upload_tmp.b64"

    # Ensure remote directory exists
    cmd_id = protocol.run_command(shell_id, "cmd", ["/c", f'if not exist "{remote_dir}" mkdir "{remote_dir}"'])
    protocol.get_command_output(shell_id, cmd_id)
    protocol.cleanup_command(shell_id, cmd_id)

    # Delete destination if it exists (certutil won't overwrite)
    cmd_id = protocol.run_command(shell_id, "cmd", ["/c", f'if exist "{remote_path}" del /f "{remote_path}"'])
    protocol.get_command_output(shell_id, cmd_id)
    protocol.cleanup_command(shell_id, cmd_id)

    # Handle empty files
    if len(raw) == 0:
        cmd_id = protocol.run_command(shell_id, "cmd", ["/c", f'type nul > "{remote_path}"'])
        protocol.get_command_output(shell_id, cmd_id)
        protocol.cleanup_command(shell_id, cmd_id)
        return

    # Standard base64 split into 76-char lines (certutil accepts this format)
    b64_full = base64.b64encode(raw).decode("ascii")
    lines = [b64_full[i:i+76] for i in range(0, len(b64_full), 76)]

    # First line: create (overwrite) tmp file
    cmd_id = protocol.run_command(shell_id, "cmd", ["/c", f'echo {lines[0]} > "{tmp_b64}"'])
    protocol.get_command_output(shell_id, cmd_id)
    protocol.cleanup_command(shell_id, cmd_id)

    # Remaining lines in batches of 60 (60 * ~78 chars ≈ 4680 chars per call, safe under 8191)
    BATCH = 60
    for i in range(1, len(lines), BATCH):
        batch = lines[i:i+BATCH]
        cmds = " & ".join(f'echo {ln} >> "{tmp_b64}"' for ln in batch)
        cmd_id = protocol.run_command(shell_id, "cmd", ["/c", cmds])
        stdout, stderr, rc = protocol.get_command_output(shell_id, cmd_id)
        protocol.cleanup_command(shell_id, cmd_id)
        if rc != 0:
            print(f"  WARN batch {i} failed: {stderr.decode()[:100]}")

    # Decode with certutil
    cmd_id = protocol.run_command(shell_id, "certutil", ["-decode", tmp_b64, remote_path])
    stdout, stderr, rc = protocol.get_command_output(shell_id, cmd_id)
    protocol.cleanup_command(shell_id, cmd_id)
    if rc != 0:
        print(f"  WARN certutil failed for {remote_path}: rc={rc} {stderr.decode()[:200]}")

    # Delete tmp file
    cmd_id = protocol.run_command(shell_id, "cmd", ["/c", f'del /f "{tmp_b64}"'])
    protocol.get_command_output(shell_id, cmd_id)
    protocol.cleanup_command(shell_id, cmd_id)


def upload_scripts(protocol, shell_id):
    """Walk scripts_2026/ and upload every .ps1 file via stdin streaming."""
    scripts_dir = os.path.join(LOCAL_ROOT, "scripts_2026")
    total = 0
    for root, dirs, files in os.walk(scripts_dir):
        for fname in sorted(files):
            if not fname.endswith(".ps1"):
                continue
            local_path  = os.path.join(root, fname)
            rel         = os.path.relpath(local_path, LOCAL_ROOT)
            remote_path = REMOTE_ROOT + "\\" + rel.replace("/", "\\")
            upload_file_via_stdin(protocol, shell_id, local_path, remote_path)
            total += 1
    print(f"  Uploaded {total} scripts.")

    # Upload the local runner
    runner_local  = os.path.join(LOCAL_ROOT, "run_all_diag_local_2026.ps1")
    runner_remote = REMOTE_ROOT + "\\run_all_diag_local_2026.ps1"
    upload_file_via_stdin(protocol, shell_id, runner_local, runner_remote)
    print(f"  Uploaded runner.")


def setup_services(ip, user, password, protocol, shell_id):
    """
    Upload setup_services_2026.ps1 and run it.
    Handles the case where a Windows restart is needed (exit code 1001).
    Returns a new (session, protocol, shell_id) tuple (may change after restart).
    """
    setup_local  = os.path.join(LOCAL_ROOT, "setup_services_2026.ps1")
    setup_remote = REMOTE_ROOT + "\\setup_services_2026.ps1"

    print("[SETUP] Uploading setup_services_2026.ps1...")
    upload_file_via_stdin(protocol, shell_id, setup_local, setup_remote)

    print("[SETUP] Running service installation (may take 3-5 minutes)...")
    s_tmp = make_session(ip, user, password)
    r = s_tmp.run_ps(
        f'$OutputEncoding=[System.Text.Encoding]::UTF8; '
        f'& "{setup_remote}"; $LASTEXITCODE',
        # run_ps wraps in cmd, so we read $LASTEXITCODE separately
    )
    stdout = r.std_out.decode("utf-8", errors="replace")
    stderr = r.std_err.decode("utf-8", errors="replace")
    rc     = r.status_code
    print(stdout[-4000:] if len(stdout) > 4000 else stdout)
    if stderr.strip():
        # filter out CLIXML progress noise
        filtered = [l for l in stderr.split('\n') if not l.strip().startswith('#<')]
        if filtered:
            print(f"  STDERR: {''.join(filtered)[:500]}")

    # Detect restart needed via exit code embedded in stdout or rc
    needs_restart = (rc == RESTART_NEEDED_EXIT) or ("Rebooting" in stdout)

    if needs_restart:
        print("[SETUP] Restart required. Rebooting VM...")
        try:
            s_tmp.run_ps("Restart-Computer -Force")
        except Exception:
            pass  # connection drops immediately after restart

        print("[SETUP] Waiting 120 seconds for VM to restart...")
        time.sleep(120)

        # Reconnect with retries
        for attempt in range(1, 7):
            try:
                print(f"[SETUP] Reconnect attempt {attempt}/6...")
                s_new = make_session(ip, user, password)
                out, _, rc2 = run_ps(s_new, "$env:COMPUTERNAME")
                if rc2 == 0:
                    print(f"[SETUP] Reconnected. Computer: {out.strip()}")
                    p_new      = s_new.protocol
                    shell_new  = p_new.open_shell()
                    # Re-run setup (features already installed, just configure)
                    print("[SETUP] Running setup again to configure services post-restart...")
                    s_new.run_ps(f'& "{setup_remote}"')
                    return s_new, p_new, shell_new
            except Exception as e:
                print(f"  Attempt {attempt} failed: {e}")
                time.sleep(20)

        print("[SETUP] ERROR: Could not reconnect after restart.")
        sys.exit(1)

    print("[SETUP] Service setup complete (no restart needed).")
    # Return fresh session/protocol/shell
    s_new     = make_session(ip, user, password)
    p_new     = s_new.protocol
    shell_new = p_new.open_shell()
    return s_new, p_new, shell_new


def run_diagnostics(session):
    """Execute run_all_diag_local_2026.ps1 on the remote VM."""
    ps = f"""
Set-Location "{REMOTE_ROOT}"
& "{REMOTE_ROOT}\\run_all_diag_local_2026.ps1"
"""
    print("[RUN] Executing diagnostics (may take 2-5 minutes)...")
    r = session.run_ps(ps)
    stdout = r.std_out.decode("utf-8", errors="replace")
    stderr = r.std_err.decode("utf-8", errors="replace")
    print(stdout[-8000:] if len(stdout) > 8000 else stdout)
    if stderr.strip():
        print(f"STDERR: {stderr[:2000]}")
    return r.status_code


def download_report(session):
    """Download the latest JSON report from the VM."""
    ps = f"""
$reportDir = "{REMOTE_ROOT}\\reports"
$latest = Get-ChildItem $reportDir -Filter "diagnostic_2026_report_latest_*.json" | Select-Object -First 1
if ($latest) {{
    $content = Get-Content $latest.FullName -Raw
    Write-Output $content
}} else {{
    Write-Output "NO_REPORT"
}}
"""
    stdout, stderr, rc = run_ps(session, ps, label="DOWNLOAD")
    if stdout == "NO_REPORT" or not stdout:
        print("No report found.")
        return None
    return stdout


def save_report(content, filename):
    report_dir = os.path.join(LOCAL_ROOT, "reports")
    os.makedirs(report_dir, exist_ok=True)
    path = os.path.join(report_dir, filename)
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    return path


def main():
    parser = argparse.ArgumentParser(description="Win-KICS-Checker 2026 Remote Test Runner")
    parser.add_argument("--ip",    default=DEFAULT_IP,   help="VM IP address")
    parser.add_argument("--user",  default=DEFAULT_USER, help="WinRM username")
    parser.add_argument("--pass",  default=DEFAULT_PASS, help="WinRM password",
                        dest="password")
    parser.add_argument("--setup", action="store_true",
                        help="Install FTP/DNS/SNMP services before running diagnostics")
    args = parser.parse_args()

    print("=" * 60)
    print("Win-KICS-Checker 2026 — Remote Execution")
    print(f"Target: {args.ip} | User: {args.user}")
    if args.setup:
        print("Mode: service setup + diagnostics")
    print("=" * 60)

    s = make_session(args.ip, args.user, args.password)
    p = s.protocol
    shell_id = p.open_shell()

    try:
        # Verify connectivity
        stdout, _, rc = run_ps(s, "$env:COMPUTERNAME", label="PING")
        if rc != 0:
            print("Cannot connect to VM. Aborting.")
            sys.exit(1)
        computer_name = stdout.strip()
        print(f"  Connected to: {computer_name}")

        # Create remote root
        run_ps(s, f'New-Item -ItemType Directory -Path "{REMOTE_ROOT}" -Force | Out-Null', label="MKDIR")

        # Optional: service environment setup
        if args.setup:
            print()
            s, p, shell_id = setup_services(args.ip, args.user, args.password, p, shell_id)
            print()

        # Upload diagnostic scripts
        print("\n[UPLOAD] Uploading scripts...")
        upload_scripts(p, shell_id)

        # Run diagnostics
        print("\n[EXEC] Running diagnostics...")
        run_diagnostics(s)

        # Download report
        print("\n[REPORT] Downloading report...")
        content = download_report(s)
        if content:
            suffix = "_svc" if args.setup else ""
            fname  = f"diagnostic_2026_report_remote_{computer_name}{suffix}.json"
            path   = save_report(content, fname)
            print(f"  Report saved: {path}")

            # Print summary
            try:
                results = json.loads(content)
                if not isinstance(results, list):
                    results = [results]
                summary = {}
                for r in results:
                    key = r.get("Result", "Unknown")
                    summary[key] = summary.get(key, 0) + 1
                print("\n--- Summary ---")
                for k, v in sorted(summary.items()):
                    print(f"  {k:<30} {v}")
                print(f"  {'Total':<30} {len(results)}")
            except Exception as e:
                print(f"  (Could not parse JSON summary: {e})")

    finally:
        p.close_shell(shell_id)

    print("\nDone.")


if __name__ == "__main__":
    main()
