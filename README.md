# Future Axis Investor Ledger

An online system for Future Axis Holdings: ventures and investor master data, a receivable/payable ledger, investor returns, monthly profit, financial statements and a ratio dashboard.

- **Hosting:** Vercel (free), deployed automatically from GitHub
- **Database and login:** Supabase (free tier), with row-level security
- **Access control:** nobody sees any data until an admin approves them

## Files

| File | Purpose |
|---|---|
| `index.html` | The whole application |
| `config.js` | Your Supabase URL and anon key (the only file you edit) |
| `vercel.json` | Security headers and hiding the site from search engines |
| `supabase/schema.sql` | Tables, security rules, approval workflow, live updates. Safe to run again. |
| `supabase/seed-example.sql` | Optional example data (invented figures) |
| `supabase/make-admin.sql` | Makes the `businessfitter` account Admin |

## Roles

| Role | See reports | Add and edit records | Approve and manage users |
|---|---|---|---|
| Admin | Yes | Yes | Yes |
| Editor | Yes | Yes | No |
| Viewer | Yes | No | No |

The **first account ever created becomes Admin automatically**. Everyone after that starts as *pending* until an admin approves them.

## Setup

### 1. Supabase: database and login
1. Go to **supabase.com** and choose **Continue with GitHub**. Click **New project**, pick the region nearest the UAE, and save the database password.
2. Open **SQL Editor → New query**. Paste all of `supabase/schema.sql` and click **Run**. Optionally do the same with `seed-example.sql`.
3. Go to **Authentication → Sign In / Providers**:
   - Keep **Allow new users to sign up** turned **ON**. The app needs it for "Request access" and "Create user". Approval protects your data, not this switch.
   - Turn **Confirm email** **OFF**, so the accounts you create can sign in straight away. Supabase's free email service only sends a few emails per hour.
   - Click **Save**.
4. Go to **Authentication → Users → Add user → Create new user**. Enter your own email and password, tick **Auto Confirm User**, and click **Create**. You are the first account, so you become Admin.
5. Go to **Project Settings → API Keys** and copy the **Publishable key** (starts with `sb_publishable_`). On older projects you can use the **anon public** key under **Legacy API Keys** instead. Then copy the **Project URL** from **Project Settings → Data API**. Never use the *secret* or *service_role* key.

### 2. GitHub: store the code
1. On **github.com**, click **+ → New repository**. Name it `future-axis-ledger`, choose **Private**, and click **Create repository**.
2. Click **uploading an existing file**. Drag in everything *inside* the folder (not the folder itself), then click **Commit changes**.
3. Open `config.js`, click the pencil icon, paste in your Project URL and anon key, and click **Commit changes**.

### 3. Vercel: put it online
1. On **vercel.com**, click **Add New → Project**. Find `future-axis-ledger` and click **Import**.
2. Set **Framework Preset** to **Other**, then click **Deploy**.
3. Open the link Vercel gives you (for example `future-axis-ledger.vercel.app`) and sign in.
4. In Supabase, go to **Authentication → URL Configuration**. Set **Site URL** to that link, add it under **Redirect URLs** as well, and click **Save**.

Every change you commit on GitHub redeploys automatically.

## Giving people access (inside the app → Users tab, admins only)

**Option A: they request, you approve**
1. Send them your site link. On the sign-in page they click **New here? Request access** and enter their name, email and a password.
2. They see "Waiting for approval".
3. In **Users → Access requests**, click **Approve as editor**, **Approve as viewer**, or **Reject**. Their screen opens the ledger as soon as you approve.

**Option B: you create the account and send the login details**
1. In **Users**, click **Create user**. Enter their name and email, pick a role, and keep or regenerate the temporary password.
2. Click **Create account**, then **Copy login details** and send them privately (WhatsApp or in person).
3. At their first sign-in they must set their own password. Until they do, their row shows **Temp password**.

**Managing members**
- Change someone's **Role** with the drop-down.
- **Disable** cuts off access immediately. **Enable** restores it.
- **Send password reset** emails them a reset link.
- The system won't let you remove or demote the last active admin, so you can't lock yourself out.

## Already set up with the earlier version?
1. Run the new `supabase/schema.sql` again in the SQL Editor. It upgrades in place and keeps your data, and your existing account becomes Admin.
2. If you turned **Allow new users to sign up** OFF earlier, turn it back **ON** (step 1.3).
3. Replace `index.html` on GitHub with the new one. Open it, click the pencil icon, paste the new contents, and commit. Vercel redeploys automatically.

## Backups and reporting
- The free Supabase plan has no automatic backups. Download the CSVs regularly, or upgrade to Pro once real investor data is in.
- The views `v_ventures`, `v_placements` and `v_ledger` make the data easy to query in Supabase, or to connect to Excel or Power BI.
