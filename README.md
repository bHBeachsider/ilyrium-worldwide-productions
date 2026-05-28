# Ilyrium S3 bucket

Canonical structure for the Ilyrium film studio's cloud storage.

## Top-level layout

- **apps/** - studio-wide tools (Unreal, Blender, DaVinci, ComfyUI, ffmpeg, Igniter)
- **shared-assets/** - reusable creative assets (3D models, audio stems, reference photos)
- **films/** - per-project work, one subfolder per film
- **archive/** - old versions, raw footage
- **scratch/** - temporary uploads

## How to use the local mirror

This directory is the canonical local mirror of `s3://ilyrium/`.

To upload a file:
1. Drop it into the appropriate subfolder here (e.g. `apps/blender/installers/blender-5.1.zip`)
2. Re-run `bootstrap_ilyrium_s3.ps1` to sync

To pull from S3:
`aws s3 sync s3://ilyrium/ . --exclude '*' --include 'films/<project>/*'`

See `reference_ilyrium_studio_brand.md` in agent memory for the full `where does X go?` table.
