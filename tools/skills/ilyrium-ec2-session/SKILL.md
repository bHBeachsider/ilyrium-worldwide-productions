---
name: ilyrium-ec2-session
description: Automate the EC2 GPU workstation lifecycle for Brad's Ilyrium studio — start the instance, refresh the security group with current home IP, connect via SSH tunnel, launch apps (ComfyUI on port 8188, future UE/Blender), monitor active session, and shut down cleanly when done. Use this skill whenever Brad says "start the EC2", "spin up the cloud GPU", "wake up the workstation", "let's use ComfyUI", "open a session", "resume cloud work", "shut down the EC2", "stop the cloud", "done for the night", "close everything", "what's the EC2 status", "is the cloud running", or any phrase signaling he wants to start, stop, connect to, or check his Ilyrium AWS GPU workstation. The skill encapsulates the multi-step procedures (start instance → wait → get new IP → update security group → SSH tunnel → launch app on EC2) into single intent-driven invocations, and bundles PowerShell scripts that do the work end-to-end without Brad memorizing the AWS CLI sequence each time.
---

# Ilyrium EC2 Session

Automates the daily lifecycle of Brad's Ilyrium GPU workstation on AWS EC2. Brad's instance (`i-030994c5371ee5de9`, g6.2xlarge in `us-east-1`) is stopped overnight to save ~$28/day and restarted when he wants to render. Every restart involves: launching the instance, waiting for it to be reachable, re-checking the public IP (changes on every start), updating the security group if his home IP rotated, opening an SSH tunnel, launching whatever app he needs, then later shutting down cleanly.

This skill encodes that entire dance as four scripts and one decision tree.

## When to invoke

**Start a session** (run `scripts/start_session.ps1`):
- "Start the EC2"
- "Spin up the cloud GPU"
- "Wake up the workstation"
- "Let's use ComfyUI" (implies start + connect + launch)
- "Open a cloud session"
- "Resume the cloud work"

**Connect to a running session** (run `scripts/connect_comfyui.ps1` or similar):
- "Connect to the EC2"
- "Open ComfyUI"
- "Start the SSH tunnel"
- "Let me get into the cloud box"

**Shut down a session** (run `scripts/stop_session.ps1`):
- "Shut down the EC2"
- "Stop the cloud"
- "Done for the night"
- "Close everything"
- "Save money, stop the box"

**Status check** (run `scripts/status.ps1`):
- "What's the EC2 status"
- "Is the cloud running"
- "How much have I been billed today"
- "Is ComfyUI still up"

**App discovery** (run `scripts/list_apps.ps1`):
- "What apps are on the EC2"
- "What's installed on the cloud"
- "List the cloud apps"
- "Show me what I have available on the GPU box"
- "Is Blender installed up there"
- "Discover apps"

## Output behavior

For start/stop/status: invoke the corresponding script via Bash (since they're PowerShell, use `pwsh <script_path>` or relay the command to the user to run locally). Capture the script's output verbatim — these scripts are designed to print clear status + the next command the user needs to run.

For "let's use ComfyUI" or similar app-launch intent: run start (if needed) then connect, but stop at the SSH-tunnel-and-launch step because that requires an interactive shell. Print the exact SSH command for Brad to paste into a fresh PowerShell window.

Don't try to "merge" multi-step output into one block. The scripts already print well-formatted summaries.

## Reference: Brad's EC2 details

Constants used across all scripts (see [[reference-ilyrium-ec2-workstation]] for the full reference):

- **Instance ID**: `i-030994c5371ee5de9`
- **Region**: `us-east-1`
- **Security group**: `sg-03fd18b34e0bceb8f`
- **PEM file (local)**: `C:\Users\bradu\.ssh\ilyrium-ue.pem`
- **Username**: `Administrator`
- **AMI snapshot**: `ami-02f4d57f2979387e9` (Ilyrium UE57 base, can be used to launch fresh instances)
- **ComfyUI install path on EC2**: `C:\ComfyUI`
- **ComfyUI port**: 8188 (tunneled locally as 8188)

## Bundled scripts

### `scripts/start_session.ps1`

Starts the EC2 instance if stopped, polls until running state, retrieves the new public IP, checks if Brad's home IP has changed and updates the security group rule if needed. Prints the SSH command Brad should run next.

### `scripts/stop_session.ps1`

Stops the EC2 instance and confirms the stop transitioned. Prints how much approximate billing was incurred since the last start (rough estimate based on instance uptime).

### `scripts/connect_comfyui.ps1`

Convenience wrapper for the most common workflow: opens an interactive SSH session with port 8188 forwarded for ComfyUI access. Inside the session, it auto-runs ComfyUI's launch helper. Brad then opens `http://127.0.0.1:8188` in his local browser.

### `scripts/status.ps1`

Reports current EC2 state, current public IP (if running), security group's current SSH-from-IP allowlist, and tries to determine if ComfyUI is actually responding through the tunnel (if a tunnel is open).

### `scripts/list_apps.ps1`

**App discovery.** SSHes into the EC2 and walks a catalog of known apps (ComfyUI, Unreal Engine 5.7, Cesium, Quixel Bridge, Epic Games Launcher, Python, AWS CLI, Git, FFmpeg, 7-Zip — extensible by editing the `$AppCatalog` array). For each app it reports:

- **installed?** — Test-Path on the canonical install location
- **running?** — process check (for apps with a meaningful process)
- **port listening?** — TCP listener check (for web-UI apps)
- **launch command** — exact PowerShell to start the app on EC2
- **description** — one-liner explanation

Output modes:
- Default: human-readable table grouped by app
- `--JsonOnly`: structured JSON for programmatic consumption by other scripts/agents

Use this when:
- Brad asks what's installed on the cloud box
- A future agent or skill needs to enumerate available capabilities before deciding which app to launch
- Confirming a fresh AMI snapshot still has everything it should before tearing the current instance down

**To register a new app** (e.g., when Brad installs Blender), open `list_apps.ps1`, append an entry to `$AppCatalog` with `name`, `install_check`, `process_name`, `web_port`, `launch_command`, `description`, and `web_ui` fields. Re-package the skill.

## Common workflows

**Daily start (most common):**
```
Brad: "let's use ComfyUI"
Skill: runs start_session.ps1, prints connection info + SSH command, then directs
       Brad to paste the SSH command in a fresh PowerShell window.
```

**Quick stop:**
```
Brad: "done for the night"
Skill: runs stop_session.ps1, confirms stop, reports billing estimate.
```

**Mid-session status check:**
```
Brad: "is the EC2 still running?"
Skill: runs status.ps1, summarizes state in 3-4 lines.
```

## Memory updates after action

If the instance's public IP changes after start, the new IP should be noted in the session context (not memory — IPs rotate too often to be worth a memory file). The instance ID and AMI ID don't change and are already in `reference-ilyrium-ec2-workstation`.

If anything structural changes — new app installed, port pattern shifts, security group restructured, AMI re-snapshotted — update `reference-ilyrium-ec2-workstation` accordingly.

## Lessons baked in

These rules are baked into the scripts so Brad doesn't have to remember them:

- **SSH tunnel uses `127.0.0.1:port`, NOT `localhost:port`** as the remote destination. Localhost resolves to IPv6 on Windows EC2 and breaks forwarding to IPv4-only services. See [[feedback-ssh-tunnel-use-127-0-0-1]].
- **PEM file may need re-tightening** of read-only permissions after editing. Scripts do this.
- **PowerShell scripts must be ASCII-only** to run cleanly on Windows PowerShell 5.1. See [[feedback-powershell-ascii-only]]. All scripts in this skill are pure ASCII.
- **Security group home-IP check is automatic** in start_session.ps1 — if Brad's residential IP has changed since the last session, the script updates the rule before he tries to SSH in.

## Cost reminder

When the skill is invoked for "stop", always include a one-line note about how much was saved (or about to be saved): "Stopped. ~$1.20/hr saved. Storage continues at ~$0.30/day."

When invoked for "start", always include a one-line note that billing is about to start: "Starting up. Billing begins at ~$1.20/hr once running state is reached."

This isn't financial advice — it's friction. Brad is running a personal studio on cloud GPU pricing and the meter matters.
