# Vercel deployment notes

After the GitHub push completes, switch back to your Vercel tab and do the following BEFORE clicking Deploy.

## 1. Change the Root Directory

The Next.js Control Panel lives at `apps/control-panel/`, not at the repo root. Vercel needs to know.

- Find the **Root Directory** field showing `./`
- Click **Edit**
- Change it to: **`apps/control-panel`**

## 2. Change the Application Preset

- Currently shows **Other**
- Change to: **Next.js**
- Vercel will auto-detect build settings (`npm install`, `next build`, `.next` output)

## 3. Environment Variables

For the first deploy, no env vars needed — the scaffold has only sample data.

Later (when orchestrator API is wired) you'll add:
- `NEXT_PUBLIC_API_URL` — orchestrator REST endpoint
- `CLERK_PUBLISHABLE_KEY` / `CLERK_SECRET_KEY` — auth
- `DATABASE_URL` — Neon Postgres (if the UI talks to DB directly for some read paths)

## 4. Click Deploy

First build takes ~2 minutes. When done, you'll get a URL like:
`https://ilyrium-worldwide-productions.vercel.app`

## What you'll see on the deployed site

- `/` Dashboard with KPI cards and tables of sample data (Kathy 01–03, NH-01–02)
- `/gates` HITL gate approval screen for the NH-04 "Library Sit-In" gate
- `/concepts` Concepts list

All data is hardcoded in the page files for now. Replacing it with real orchestrator data is one of the Phase B sprints in the COO Plan.

## If the build fails

Most likely causes and fixes:

| Error | Fix |
|---|---|
| `package.json not found` | Vercel Root Directory wasn't changed — set to `apps/control-panel` |
| `Module not found: tailwindcss` | Vercel auto-installs from package.json on retry; force a redeploy |
| TypeScript errors | Add `"ignoreBuildErrors": true` to next.config.mjs (temp) |

## After first deploy works

In the Vercel project Settings → Git, the connection is now live. Every `git push` to `main` will trigger a new build.

Branch deploys: pushing to any other branch creates a preview URL. Useful for testing UI changes before promoting to production.
