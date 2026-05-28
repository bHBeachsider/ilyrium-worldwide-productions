# Neon · setup and connection

This guide creates the `Ilyrium Studio OS` Postgres database in the `Ilyrium.io` Neon org and wires it to the Control Panel app on Vercel.

Time: ~10 minutes.

## Step 1 — Create the Neon project

In the Neon console (the tab you have open at console.neon.tech):

1. Click **Create project**
2. Project name: `studio-os`
3. Postgres version: **17** (latest stable)
4. Region: **AWS US East 2 (Ohio)** *(or whichever is closest to your Vercel project region; default us-east-2 is fine)*
5. Database name: `ilyrium` *(default `neondb` also works — just match it in the connection string)*
6. Click **Create project**

Neon will provision the database in a few seconds and show the connection details.

## Step 2 — Copy the POOLED connection string

The project page shows a "Connection Details" panel.

1. Set the dropdown to **Pooled connection** (NOT direct — pooled is required for serverless Vercel functions)
2. Copy the string — it looks like:
   ```
   postgresql://neondb_owner:abc123XYZ@ep-cool-snow-12345-pooler.us-east-2.aws.neon.tech/ilyrium?sslmode=require
   ```
3. The hostname must contain `-pooler` — if it doesn't, you copied the direct one.

**Treat this string like a password.** It contains the database password in cleartext. Do not commit it; do not paste it in chat or in any file.

## Step 3 — Apply the spine migration

While still in the Neon console:

1. Click **SQL Editor** in the left sidebar
2. Open the file: `C:\Users\bradu\Documents\Ilyrium\apps\control-panel\db\migrations\0001_studio_os_spine.sql`
3. Paste its contents into the SQL Editor
4. Click **Run**

Expected result:
- `CREATE EXTENSION` (×2)
- `CREATE TABLE` (×17)
- `CREATE INDEX` (×20+)
- Zero errors

To verify, run the verification query at the bottom of the migration file:
```sql
select count(*) as table_count from information_schema.tables where table_schema='public';
```
Expect **17**.

## Step 4 — Add DATABASE_URL to Vercel

In your Vercel project (the tab where you imported `ilyrium-worldwide-productions`):

1. After deploy completes, go to **Project → Settings → Environment Variables**
2. Add a new variable:
   - **Key**: `DATABASE_URL`
   - **Value**: the pooled connection string from Step 2
   - **Environments**: check all three — **Production**, **Preview**, **Development**
3. Click **Save**
4. **Important**: Vercel will NOT apply env var changes to the existing deployment. Go to **Deployments**, find the latest, click the ⋯ menu, and select **Redeploy** *with* "Use existing Build Cache" unchecked.

After redeploy, visit `https://<your-deploy-url>/settings` — it should show:
- `DATABASE_URL env var: set`
- `Connection: Connected`
- `Tables in public schema: 17`
- Green confirmation: "Studio OS spine is live"

## Step 5 — Add DATABASE_URL locally (optional but recommended)

For `npm run dev` to work with the DB, create `apps/control-panel/.env.local`:

```
DATABASE_URL="postgresql://neondb_owner:...@ep-...-pooler.us-east-2.aws.neon.tech/ilyrium?sslmode=require"
```

This file is git-ignored (the scaffold's `.gitignore` already excludes `.env.local`). Never commit it.

## Troubleshooting

| Symptom | Fix |
|---|---|
| Settings page shows "DATABASE_URL: NOT SET" after redeploy | Env var wasn't applied; force a fresh redeploy without cache |
| "Connection: Failed" with timeout error | You used the direct (non-pooled) connection. Switch to pooled. |
| "Tables in public schema: 0" | Migration didn't run. Re-run the SQL in Neon's editor. |
| Migration error about `vector` extension | Older Neon project — upgrade Postgres version or omit the `text_embedding` column / pgvector index for now |
| `permission denied for schema public` | Use the connection string from the project page (it has the right role); don't use a custom user |

## What this unlocks

Once `/settings` shows all green:

- The Studio OS spine is provisioned and ready
- Future pages can swap from sample data → live queries by importing `sql` from `@/lib/db`
- The next slice (per COO Plan Sprint A1) is to insert real Kathy Flyover + New Harmony rows so the Dashboard reads from the DB instead of hardcoded arrays
