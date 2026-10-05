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
| CFO | Yes | Yes (incl. Settings, Start again) | No, and can't see other users |
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

## Activity log (Log tab, Admin and CFO)
- Every record added, changed or deleted is logged by the database itself, with who did it, when, and the values before and after. Nobody can edit or delete the log, including admins.
- Also logged: sign-ins (visible to Admin only), statement uploads, accrual runs, imports, emails sent, backups and restores.
- Filter by date, area, action or person, click a row for the full before/after, and download the log as CSV.

## Backups (Backups tab, Admin and CFO)
- **Automatic:** one full copy a day, kept for 30 days. It is taken at the first sign-in each day, and also at 02:00 Dubai time if pg_cron is enabled in Supabase (Database → Extensions → pg_cron).
- **Manual:** "Save backup in Supabase" with a label (e.g. *Before September close*). Kept until you delete it.
- **Download backup file:** keep a copy outside Supabase (OneDrive or Google Drive) at least weekly. The app reminds you after 7 days.
- **Restore** from a saved backup or a downloaded file. A copy of the current data is always saved first, so a restore can be undone.
- **Start again** now saves a backup automatically before deleting.
- Users and passwords are not part of backups.
- The views `v_ventures`, `v_placements` and `v_ledger` make the data easy to query in Supabase, Excel or Power BI.

## Monthly investor report (Reports tab)
- Every investor and placement with amount, agreed profit rate, profit for the month, profit to date and payable, as at month end, in **Excel and PDF**.
- Set the email addresses (several allowed, comma-separated), the day of the month, and tick **Send automatically every month**.
- On or after that day, the first Admin or CFO to sign in sends last month's report automatically. The Dashboard shows an alert until it has gone, and if sending fails it retries at the next sign-in.
- Only the first address needs FormSubmit's one-time activation click. The others are copied.

## Dashboard
- Hover over or tap any chart, bar or KPI to see figures and percentages. Tapping pins the tooltip; tap elsewhere to close it.
- **Recommendations** show the 3–4 most important points from the figures: cash cover for investor payouts, collections, rate spreads, concentration, maturities, unrecorded bank lines and missing accruals.
- Actual returns and ratios use time-weighted average capital up to the last profit posted.

## Importing investors (Import investors tab), one-time setup
1. Click **Download template**: Sr. #, Investor, Annual profit rate, Placement Date, Investment (USD), and one column per venture.
2. Fill one row per placement and split the amount across the venture columns.
3. Upload it. The preview lets you edit any cell, tick which rows are paid-up capital (FAMCON is ticked automatically), or remove rows. Then click **Import**.
4. After that, add or edit investors in the **Investors** tab (Edit button on each row).

## Bank statements and reconciliation (Bank tab)
- **Upload statement** accepts Wio Bank **PDF** statements as downloaded, plus Excel/CSV exports from any bank (you map the columns).
- Each PDF is checked: opening balance + all lines must equal the closing balance, and every running balance must agree.
- Lines that match an existing ledger entry (same amount, within 10 days) are matched automatically.
- You're then prompted to **record** the remaining lines: pick the type (and venture or placement where needed). Suggestions come from your ventures and from how you recorded similar lines before.
- The reconciliation statement shows balance per statement vs balance per books, with all reconciling items. It reconciles at the period end chosen at the top.

## Profit accruals (Ledger / Investor returns / Dashboard → Run profit accruals)
- **Venture profit** = each venture's expected rate × capital invested in it, day by day, posted at each month end.
- **Investor profit** = each placement's agreed rate × the placement, day by day from the day after placement (until maturity).
- Future Axis keeps the difference on investor money, plus the full venture profit on paid-up capital. The Dashboard and P&L show these separately.
- Re-running recalculates the chosen months and replaces earlier automatic entries, for example after a rate change or a new placement. Entries made by hand are left alone.

## Currencies
- **Base currency: USD.** All ventures, placements and ledger amounts are stored in USD. The Import template amounts are in USD.
- **View in AED:** use "Show in" at the top of the screen (remembered per device), or set the default in Settings. The rate (AED per 1 USD, default 3.6725) is set in Settings.
- **Bank accounts keep their own currency** (e.g. Wio in AED). Statements stay in AED, and reconciliation converts the books into the account's currency. Entries recorded from a bank line keep the exact AED amount, so they always match.
- Admins can wipe all business data under **Settings → Start again** (users and settings are kept).

## Expenses and suppliers (Expenses tab)
- **Suppliers:** add your service providers (e.g. in Pakistan) with their bank details and a default expense category.
- **Confirm from bank statements:** every payment out of an uploaded statement that isn't matched yet is listed as a template. Edit the description, supplier, category or amount, untick lines that aren't expenses (e.g. investor payouts), then click **Confirm**. AED amounts are converted to USD at the Settings rate. The original AED amount is kept, so the bank line stays matched (unless you changed the amount).
- **Add expense:** record one by hand in AED or USD, optionally with the PKR the supplier received and the invoice number.
- The P&L shows expenses by category.

## Emails to finance
- Income entries and investor-portal profit go to the email address you type, through FormSubmit. You don't need to connect Gmail. The first time, the recipient clicks an activation link once.
- A PDF of the entry is attached. If an email arrives without it, use **Download PDF** and forward it.
