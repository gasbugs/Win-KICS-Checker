# Project Plan

This document outlines the high-level plan and ongoing progress for the Win-KICS-Checker project.

## Phase 1: Initial Setup and Core Diagnostics (Completed)
- Basic PowerShell script structure for diagnostics.
- Local execution of individual diagnostic scripts.
- Basic reporting (CSV, JSON).

## Phase 2: Remote Diagnostics and Enhanced Reporting (In Progress)
- Implement remote execution capabilities for diagnostic scripts.
- Centralized logging for remote diagnostics.
- Enhanced reporting with summary and detailed views.
- Integration with Vagrant for test environment provisioning.

## Phase 3: Expanding Diagnostic Coverage (Ongoing)
- Implement diagnostics for all KICS (Korea Information Security Certification) items.
- Focus on specific categories (e.g., Account Management, Service Management).

### Diagnostic Script Updates (2025-09-15)

- **W-38 (Screensaver Setting):** Modified to use direct registry check for `ScreenSaveActive`, `ScreenSaverIsSecure`, and `ScreenSaveTimeOut`.
- **W-40 (Force Shutdown Remote System):** Restored original logic to check assigned users for `SeRemoteShutdownPrivilege`, and removed `/areas SECURITYPOLICY` from `secedit /export` command.
- **W-44 (Allow Removable Media Format Eject):** Changed check to use `allocateDASD` registry value.
- **W-46 (Network Access: Do Not Allow Anonymous Enumeration of SAM Accounts and Shares):** Script updated by user for proper checking.
- **W-47 (Account Lockout Duration Setting):** Modified to compare lockout duration and reset counter directly in minutes (60 minutes recommended).
- **W-50 (Maximum Password Age):** Modified to compare password age directly in days (90 days recommended).
- **W-52 (Do Not Display Last User Name):** Script updated by user for proper checking.
- **W-53 (Allow Local Logon):** Script updated by user for proper checking.
- **test_env/provisioning/install_features.ps1:** Added BitLocker feature installation.

Updated diagnostic report files in `reports/` directory.
