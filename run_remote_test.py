#!/usr/bin/env python3
"""
Win-KICS-Checker 2026 — Remote Test Runner
Copies scripts_2026/ to Windows VM via WinRM and executes the diagnostic suite.
"""
import os
import sys
import base64
import json
import winrm
import warnings
warnings.filterwarnings("ignore")

VM_IP   = "34.22.96.68"
VM_USER = "kicstest"
VM_PASS = "Iu5DwA9$P(067@["
REMOTE_ROOT = r"C:\kics2026"
LOCAL_ROOT  = os.path.dirname(os.path.abspath(__file__))


def make_session():
    return winrm.Session(
        f"http://{VM_IP}:5985/wsman",
        auth=(VM_USER, VM_PASS),
        transport="ntlm",
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
    print("=" * 60)
    print("Win-KICS-Checker 2026 — Remote Execution")
    print(f"Target: {VM_IP} | User: {VM_USER}")
    print("=" * 60)

    s = make_session()
    p = s.protocol

    # Open a persistent shell for uploads (avoids shell-per-command overhead)
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

        # Upload
        print("\n[UPLOAD] Uploading scripts...")
        upload_scripts(p, shell_id)

        # Run
        print("\n[EXEC] Running diagnostics...")
        run_diagnostics(s)

        # Download report
        print("\n[REPORT] Downloading report...")
        content = download_report(s)
        if content:
            fname = f"diagnostic_2026_report_remote_{computer_name}.json"
            path  = save_report(content, fname)
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
