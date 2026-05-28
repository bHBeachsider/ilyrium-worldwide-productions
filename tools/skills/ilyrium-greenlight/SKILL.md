---
name: ilyrium-greenlight
description: Produce a structured greenlight verdict for any Ilyrium film-studio action that's about to be shipped. Use this skill whenever the user asks "should I ship", "ready to render v10", "greenlight this", "ok to push to S3", "should I snapshot the AMI", "ok to stop the EC2", "ready to apply the dialogue placement", or any phrase that signals they're about to commit a non-trivial action (render, S3 push, AMI snapshot, EC2 stop/start, --apply on a destructive script, delete a backup). The skill validates the proposed action against the user's accumulated discipline memory rules and current project state, then outputs a greenlight decision with explicit next-action command and post-action memory plan. Always use this skill before any of these actions are taken so Brad gets a deliberate "yes/wait/no" verdict instead of just barreling forward.
---

# Ilyrium Greenlight

A structured pre-action verdict skill for Brad's Ilyrium AI film studio. Whenever Brad is about to take a non-trivial action — render a film cut, push assets to S3, snapshot the EC2 AMI, run an `--apply` script that mutates DaVinci or Blender state, delete a backup — pause and produce a structured greenlight document.

The output is not just "yes" — it's a deliberate verdict that:
- Cross-checks the action against Brad's discipline memory rules
- Reports relevant pre-flight state (DaVinci, EC2, S3, etc.)
- Catches structural problems (path drift, IP issues, dependency gaps)
- Specifies the exact next-action command
- Plans what to record in memory after the action completes

This exists because Brad accumulates studio infrastructure faster than he can mentally check it all every time. The skill encodes the checklist.

## When to invoke

Strong triggers (always run the skill):
- "Should I render v10"
- "Ready to ship"
- "Greenlight this"
- "Ok to push to S3"
- "Should I snapshot the AMI"
- "Ok to stop the EC2"
- "Ready to apply"
- "Ok to delete [film_projects backup, old audit, scratch dir]"

Medium triggers (run unless context makes it obviously trivial):
- "Should I do X" where X is a write/destructive script call
- "Ready for the final render"
- Any `--apply` invocation about to happen

Do NOT run for:
- Pure dry-runs (no mutation)
- Read-only audits (`python audit_davinci_project.py`)
- Pure conversation / planning

## Output structure

Always produce the verdict in this exact shape. Lead with the headline decision, then back it up with evidence.

```
[GREENLIGHT / WAIT / HOLD] to <action>. <one-line rationale>.

Pre-flight check this round:
* <state observation 1 — e.g., A1-A6 confirmed empty per latest audit>
* <state observation 2 — e.g., EC2 i-030994c5371ee5de9 stopped, OK to skip>
* <state observation 3 — e.g., No render queue jobs currently active>

Discipline observations this round:
* <which memory rules apply — e.g., script-don't-click respected, scripts written to Ilyrium not film_projects>
* <discovery catch — e.g., the freqman peak at frame 586 has the audio peak landing at video frame 830, matches V4 ground POV midpoint>
* <or: gap flagged — e.g., no recent audit on disk, recommend re-running before --apply>

<Counter / pattern note. E.g., "Third successful filename-time placement strategy run, pattern holds." Or "First time running this script post-EC2-setup, watch for fresh failure modes.">

Proceed with: <exact PowerShell or bash command>

Standard follow-up: <any habitual cleanup, e.g., "audit after to verify, then render --duration-s 60">

After <action> completes, update memory:
* <Memory update 1 — e.g., new instance ID if launched>
* <Memory update 2 — e.g., bump the "X consecutive Y" counter>
* <Memory update 3 — e.g., new finding to record>
```

## How to fill each section

### Headline decision

Three options:
- **GREENLIGHT** — clear yes. Pre-flight clean, all discipline rules respected, action is reversible OR risk is acceptable.
- **WAIT** — soft no. Some pre-flight check failed (stale audit, EC2 not in expected state, missing dep) but the user can fix it in <5 min and re-ask.
- **HOLD** — hard no. Action would violate a saved discipline rule (e.g., trying to write to `film_projects/` instead of `Ilyrium/`), or risks irreversible damage. Explain why and what to do instead.

Don't soften the verdict. If it's HOLD, say HOLD. The skill loses value if every check returns GREENLIGHT regardless.

### Pre-flight checks

Read the relevant state. Common sources:
- **Memory files** in the user's memory dir — check for action-relevant references (e.g., the EC2 instance ID for an EC2 action, the AMI ID for a snapshot action)
- **Latest audit JSON** in `C:\Users\bradu\Documents\Ilyrium\tools\davinci_audits\` for DaVinci actions
- **`aws ec2 describe-instances`** for EC2 state questions
- **`aws s3 ls`** for S3 sync questions

3-5 observations is the sweet spot. Avoid padding with irrelevant state.

### Discipline observations

Brad's memory accumulates rules. Cross-reference the proposed action against them. Read `MEMORY.md` for the current full list — these are some examples but the list grows:

- `feedback-script-dont-click` — scripted actions preferred over GUI clicks
- `feedback-write-to-ilyrium` — new files go in `C:\Users\bradu\Documents\Ilyrium\`, NOT `film_projects\`
- `feedback-powershell-ascii-only` — `.ps1` files must be ASCII (no em-dashes, etc.)
- `feedback-davinci-deleteclips-unreliable` — script ADD, manual DELETE
- `feedback-no-2d-cockpit-overlay` — no 2D overlay attempts for pilot POV
- `feedback-ssh-tunnel-use-127-0-0-1` — SSH `-L` destination uses 127.0.0.1, not localhost
- `feedback-blender-slotted-actions` — Blender 4.4+ slotted action iterator
- `feedback-blender-vse-strips-rename` — Blender 5.x VSE strips rename helpers

Call out specific rule names when relevant — "wrote to Ilyrium not film_projects [[feedback-write-to-ilyrium]]" both proves the check was done and lets Brad jump to the rule if he wants context.

### Pattern / counter note

If Brad has a running streak or pattern, mention it. Examples:
- "Third v8.1 dialogue placement, filename-time strategy holds"
- "First render since AMI snapshot — watch for missing model dependencies"
- "Fifth consecutive ASCII-clean PowerShell script, no encoding regressions"

If there's no relevant pattern, skip this line. Don't manufacture one.

### Next action command

Exact PowerShell or bash. Copyable. No placeholders unless the user must fill them. Use Brad's canonical paths:
- Scripts: `C:\Users\bradu\Documents\Ilyrium\films\<film>\scripts\<script>.py`
- Tools: `C:\Users\bradu\Documents\Ilyrium\tools\<area>\<script>.ps1`
- PEM: `C:\Users\bradu\.ssh\ilyrium-ue.pem`
- Instance: `i-030994c5371ee5de9` (current EC2)

### Memory update plan

Concrete bullets, not "I'll update memory." Specify the file or pattern:
- "Increment 'consecutive --apply runs without rollback' counter in `feedback-script-dont-click`"
- "Record new AMI ID in `reference-ilyrium-ec2-workstation`"
- "Save finding about the V4 ground POV midpoint drift as `feedback-v4-ground-pov-midpoint`"

If nothing memory-worthy, say "No memory update needed." Don't pad.

## Common action shapes and their checks

For each action shape, this is what good pre-flight looks like:

**Render a film cut** (e.g., `render_timeline.py --duration-s 60`)
- Latest audit shows expected track state (A1-A8 populated as intended)
- No fragmented clips on A8 (the F-18 audio bug from 2026-05-27)
- A9 JET BED present with appropriate volume
- DaVinci is running and the right project is open
- Output folder exists

**EC2 launch / start / stop**
- AWS CLI configured locally
- Security group still has SSH from current home IP (check via `aws ec2 describe-security-groups`)
- For start: previous instance was actually stopped (not terminated)
- For stop: nothing actively rendering or downloading
- PEM file readable (cross-check `~/.ssh/ilyrium-ue.pem` exists)

**AMI snapshot** (`aws ec2 create-image`)
- Instance is in `running` state
- Recent install/config work is complete (don't snapshot mid-install)
- Snapshot name follows `ilyrium-<purpose>-base` convention
- Description includes what's installed

**`--apply` on destructive script** (place_dialogue, restore_video_tracks, etc.)
- Dry-run was run first (check recent terminal history if possible)
- Backup or audit captured the pre-state
- For place_dialogue / restore_video: target tracks confirmed empty (or orphans only)
- For place_jet_audio: A8 confirmed empty

**Push to S3** (`aws s3 sync` or `cp`)
- Source path follows the canonical Ilyrium layout (`apps/`, `shared-assets/`, `films/`)
- Files don't contain secrets (PEM, API keys, .env)
- Destination matches canonical S3 layout (`s3://ilyrium/<area>/...`)
- Bucket is the correct one (`ilyrium`, not a personal-use bucket)

**Delete a backup** (e.g., `film_projects/Blue_Angels_Kathy_Flyby/`)
- Equivalent content confirmed present in canonical Ilyrium location
- No active scripts reference the old path (grep first)
- The current latest film render is on disk somewhere stable

If you don't have the data to verify a check, say so explicitly — "Pre-flight gap: no recent audit on disk, recommend running `audit_davinci_project.py` first." Don't fabricate a passing check.

## Tone

Match Brad's terse, direct style. He's been at this long enough to want signal, not handholding. A good verdict is 15-25 lines total. If it's 50+ lines you're over-explaining.

Lean on memory `[[wikilinks]]` so Brad can jump to context — don't restate rules he already knows.
