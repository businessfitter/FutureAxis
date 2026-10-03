# Future Axis Investor Ledger

An online system for Future Axis Holdings: ventures and investor master data, a receivable/payable ledger, investor returns, monthly profit, financial statements and a ratio dashboard.

- **Hosting:** Vercel (free), deployed automatically from GitHub
- **Database and login:** Supabase (free tier), with row-level security
- **Access:** only people you add as members can see anything. Each member is either an `editor` or a `viewer`.

## Files

| File | Purpose |
|---|---|
| `index.html` | The whole application |
| `config.js` | Your Supabase URL and anon key (the only file you edit) |
| `vercel.json` | Security headers and hiding the site from search engines |
| `supabase/schema.sql` | Creates the tables, security rules and live updates |
| `supabase/seed-example.sql` | Optional example data (invented figures) |

## Setup (about 20 minutes)

### 1. Supabase: database and login
1. Sign up at **supabase.com**, then choose **New project**. Pick region **Middle East (UAE)** or the nearest one, and set a strong database password.
2. Open **SQL Editor → New query**. Paste all of `supabase/schema.sql` and click **Run**.
3. Optional: run `supabase/seed-example.sql` the same way to load example data.
4. Go to **Authentication → Sign In / Providers**. Turn **off** "Allow new users to sign up" so that only people you create can get in.
5. Go to **Authentication → Users → Add user → Create new user**. Enter your email and a password, and tick **Auto Confirm User**.
6. Make yourself an editor by running this in the SQL Editor:
   ```sql
   insert into public.members (user_id, role)
   select id, 'editor' from auth.users where email = 'you@example.com';
   ```
7. Go to **Project Settings → API** and copy the **Project URL** and the **anon public** key.

### 2. GitHub: store the code
1. Sign in at **github.com** and choose **New repository**. Name it `future-axis-ledger` and set it to **Private**.
2. On the new repository page, click **uploading an existing file**. Drag in all the files and the `supabase` folder from this package, then click **Commit changes**.
3. Open `config.js` in GitHub and click the pencil icon. Paste your Project URL and anon key, then **Commit changes**.

### 3. Vercel: put it online
1. Go to **vercel.com** and choose **Sign up → Continue with GitHub**.
2. Click **Add New → Project**, find `future-axis-ledger` and click **Import**.
3. Set **Framework Preset** to **Other**. Leave Build Command and Output Directory empty, then click **Deploy**.
4. When the deploy finishes you get a link like `future-axis-ledger.vercel.app`. Open it and sign in.
5. Back in Supabase, go to **Authentication → URL Configuration**. Set **Site URL** to your Vercel link and add the same link under **Redirect URLs**. Password-reset emails need this to come back to your site.

From now on, every change you commit on GitHub redeploys to Vercel automatically within about a minute.

### Optional: your own domain
Go to **Vercel → Project → Settings → Domains** and add, for example, `ledger.futureaxis.ae`. Then create the DNS record Vercel shows you at your domain registrar. After that, update the Site URL in Supabase to the new domain.

## Adding colleagues
1. In Supabase, go to **Authentication → Users → Add user** and create the user. Alternatively, use **Send invitation**: the person gets an email link and chooses their own password.
2. Grant access:
   ```sql
   insert into public.members (user_id, role)
   select id, 'viewer' from auth.users where email = 'colleague@example.com';
   -- use 'editor' instead of 'viewer' to let them add and change records
   ```
3. To remove someone, run `delete from public.members where user_id = (select id from auth.users where email = '...');`

## Backups and reporting
- Supabase's free plan does not include automatic backups. Use the CSV downloads in the app regularly, or upgrade to the Pro plan for daily backups.
- The schema creates three views, `v_ventures`, `v_placements` and `v_ledger`, so you can query the data in Supabase's Table Editor or connect it to Excel or Power BI.
