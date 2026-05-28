# Ilyrium Studio OS · Control Panel

Next.js 15 + Tailwind scaffold. Implements the v0.1 design from
`Ilyrium_ControlPanel_Orchestration_Design.docx` (Part I).

## What's here

- `/` — Dashboard (KPI cards + recent releases + cost panel + active agent runs)
- `/gates` — HITL gate approval screen
- `/concepts` — Concepts list

All data is sample data from New Harmony + Kathy Flyover until the orchestrator API is wired.

## Local dev

```
cd apps/control-panel
npm install
npm run dev
```

Then open http://localhost:3000

## Vercel deploy

This app is the Vercel root for the `ilyrium-worldwide-productions` repo.
Set Vercel **Root Directory** to `apps/control-panel`.
Framework preset: **Next.js** (Vercel auto-detects).

## Next slices (matches the design doc's 90-day mapping)

- Wire the REST API surface from the orchestrator (Part III §3.1)
- WebSocket channel for live gate updates
- Real auth via Clerk
- Shot detail page with takes grid
- Agent run detail with full trace
