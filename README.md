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


## Screens
**Dashboard · Portfolio · Investors · Ventures · Statements · Share capital · Master data** | Ledger · Bank · Expenses | Returns · Monthly · Reports | **Settings** (General, Currencies, Users, Import, Log, Backups)

## Portfolio
- Total position by venture with percentages, profit income and expected against actual rates.
- Switch between **Total portfolio**, **Investor money** (earned, investor share, kept by Future Axis) and **Share capital** (own capital, owner income, return).
- Includes month-by-month investment raised and placed, split between investor money and owner money, with charts.

## Share capital
**Closing owner equity = Paid-up capital + Retained earnings carried forward**

| Paid-up capital | Retained earnings |
|---|---|
| Paid-up capital brought forward | Retained earnings brought forward |
| + Initial paid-up capital | + Profit on initial capital |
| + Additional capital contributed | + Profit on additional investment (investor money, net of investor share) |
| − Drawings / capital withdrawn | ± Other income less operating expenses |
| = Paid-up capital | = Retained earnings carried forward (next period's brought forward) |

- Shown for the period and inception to date, with a check against total assets − total liabilities.
- Initial paid-up capital covers contributions up to a date you can change on the page. Later contributions are additional capital.
- **Trail of owner money**: every contribution, placement of own money in a venture, withdrawal from a venture and drawing, with payment details, receipts and running balances (in ventures / not yet placed). Investor money placed in ventures is excluded. Use **Place own money in a venture** to record new placements of own money.
- FAMCON is Future Axis's own company and always sits in Share capital. If it is ever recorded as an investor placement, the first Admin, CFO or Editor to sign in moves it automatically:
  - A backup is saved first.
  - The placement becomes a FAMCON capital contribution, and its venture investment becomes owner money.
  - Investor accruals on it are removed and profit accruals are re-posted.
  - A note on the Dashboard and Share capital confirms the move.
  - Placements with investor payments or withdrawals already recorded are left for you to review, using **Move to share capital** on the Investors tab.

## Currencies (Settings → Currencies)
- Profit is calculated in USD. Each investor is paid in their own currency: set **Paid in currency** in Master data, or tick placements on the Investors tab and use **Paid in… → Apply**.
- Rates are units per 1 USD and dated. The latest rate on or before a date is used. **Get latest rates** pulls market rates; you can also enter your bank's rate.
- Investors tab and monthly report show profit and payable in the payout currency.
- **Mark paid** asks for the rate of each currency involved, records the USD amount settled, the amount paid in PKR/AED and the rate, and can save the rate to the table.
- Withdrawals and payments entered in PKR or AED convert to USD at the dated rate.
- The converter on the same page converts any amount on any date.

## Ventures: profit treatment and monthly position
- Each venture has a **Profit treatment** (edit the venture):
  - **Reinvested (compounds)**, e.g. Empyrean: each month's profit is added to the investment at month end and earns profit from the next day.
  - **Paid out monthly**, e.g. SK Livestock: each month's profit is received in full at month end. This is skipped if you already recorded a receipt for that month.
  - **Kept as receivable**: profit stays receivable until you record it as received.
- **Monthly position by venture** (Ventures tab): opening position, invested, profit accrued, reinvested, received, withdrawn, receivable, investment and closing position, plus profit % p.a. for every month. Includes charts and a CSV download.
- **Record withdrawals**: paste one line per withdrawal, e.g. `May 31, 2026 - USD 13,000`.
  - For a reinvesting venture, the withdrawal reduces the investment.
  - Otherwise it settles the receivable first, and any excess reduces the investment.
  - Post the profit accruals again afterwards.

## Investor payments (Investors tab → Investor summary)
- Per investor for the chosen month: **payable b/f + profit for the month = total due**, then paid in (currency), paid (currency amount), paid converted to USD, and **payable c/f**.
- **Payment details bar** above the table: date, mode, bank, reference and an optional receipt. These apply to every payment you mark.
- **Mark paid** on a row opens an inline strip with no pop-up: currency paid in (defaults to the investor's), rate, and amount in that currency (pre-filled with the amount due). The USD equivalent is shown as you type. Click Save.
- **Bulk:** tick investors, or click **All PKR / All AED / All USD** to select everyone paid in one currency. Enter that currency's rate once and click **Mark N paid in full**.
  - Less than due: the difference stays payable and carries to next month's b/f.
  - More than due: shown **in red**, and saved only after you confirm. The row and a banner stay red, and the credit reduces the next month's due.
- **Mark all paid up to [month]**: settles everything outstanding for every investor in one step (for example, "up to Aug 2026").
- FAMCON is never paid: any payments recorded against it are removed when it moves to Share capital, and its profit stays in retained earnings.

## Other income (own tab)
- Record deal / arrangement fees, advisory & management fees, bank profit / interest, exchange gains and other income: date, category, received from, description, amount and currency (converted to USD at the dated rate), bank, mode, reference and receipts.
- Shows as its own head in the financial statements, both period and month by month, with category lines. It also appears in the share capital statement and as its own sheet in the Excel report.
- Income recorded from bank statements as "Other Income" appears on the tab too.

## Share capital (owner funds)
**Share capital (owner funds) = everything not owed to investors = total assets − investor capital − investor profit payable.**

The same figure appears on Portfolio and Share capital, split into:
- **In ventures:** venture positions less investor capital.
- **Outside ventures:** cash + profit receivable − investor profit payable.
- **Made up of:** paid-up capital + retained earnings.

If cash shows negative, receipts such as venture withdrawals aren't recorded yet.

## Master data
- One place to create, edit, **deactivate** and reactivate **investors, ventures, bank accounts and suppliers**.
- Inactive records stay on past entries but can't be chosen for new ones.
- Investors have an ID (I001…), contact details, payout bank and IBAN, payout currency, default payout frequency and portal setting.
- Placements choose the investor from master data. Renaming an investor updates all their placements.
- Existing placements that only carry a name: **Master data → Investors → Create and link** (one click). Investor imports link automatically.

## Investors tab
- **Investor summary** for the chosen month: closing investment, profit for the month, paid and outstanding, by investor.
- **Investment raised and placed, month by month**: money raised from investors, withdrawals, and money placed in ventures from investor money and from owner money, with charts and a venture filter.
- **Monthly profit and payments**: tick placements (or select all), then:
  - **Mark paid**: pays everything outstanding up to that month, with date, mode, bank, currency, reference and receipts
  - **Mark unpaid**
  - **Payout frequency**: set for all ticked placements at once
- Payout months: monthly; quarterly (Mar, Jun, Sep, Dec); semi-annual (Jun, Dec); annual (Dec); at maturity.
- **Add withdrawal**: partial or full capital withdrawal. It can also take the amount out of the venture. A full withdrawal closes the placement. Re-run profit accruals afterwards.
- A new placement records the matching **investment in the venture** automatically (tick box on the form).

## Payment details and receipts
- Placements, venture investments and withdrawals, withdrawals, profit payments and other cash entries record:
  - mode of payment: Bank transfer, Cash, Cheque, **Profit adjustment**, Card or Other
  - the counterparty's bank name (for bank transfers)
  - payment currency and amount in that currency (AED and USD convert automatically)
  - payment reference
  - **receipts** (PDF or photos, up to 10 MB each)
- Receipts are stored privately in Supabase Storage. Only approved users can open them, and only Admin, CFO and Editor can add or remove them. A paperclip badge shows on entries that have receipts.
- **Profit adjustment** moves no cash. Record both sides (for example, profit paid and the new placement it funds), so cash nets to zero. These entries stay out of bank reconciliation.
- Backups contain the records and the receipt links, but not the receipt files themselves.

## Statements tab
- **Statements**: the period and inception-to-date view.
- **Month by month**: profit or loss, financial position (month end) and cash flows, with one column per month and a total.
- **Charts**: net profit by source, income and costs, assets, funding and cash flows by month.

## Activity log (Settings → Log, Admin and CFO)
- Every record added, changed or deleted is logged by the database itself, with who did it, when, and the values before and after. Nobody can edit or delete the log, including admins.
- Also logged: sign-ins (visible to Admin only), statement uploads, accrual runs, imports, emails sent, backups and restores.
- Filter by date, area, action or person, click a row for the full before/after, and download the log as CSV.

## Backups (Settings → Backups, Admin and CFO)
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

## Cash, venture profit and withdrawals (5 Oct 2026)
- **Cash per books** (Dashboard, Portfolio) = recorded inflows − outflows. If money was reinvested but not recorded, it shows as cash: use **Reinvest cash in a venture** to clear it. Bank statement balances are compared when uploaded.
- **Run profit accruals** is now on the Investors tab.
- **Reinvested (compounds)** ventures (Empyrean): monthly profit stays as a **receivable that earns profit**. Withdrawals reduce the receivable first; any excess reduces the investment.
- **Paid out monthly** ventures (SK Livestock): each month's profit is booked as received, so the receivable stays 0.
- **Record withdrawals**: on Empyrean it comes pre-filled with the six withdrawals (31 May to 1 Oct 2026). If withdrawals were already entered, tick *Replace* to avoid double counting.
- **Ventures → All ventures**: a total monthly table, charts, position by venture, and an investment/receivable split.
- **Other income → Reinvested directly into a venture**: books the income and the investment together, with no cash.
- **Ventures → Add investment** (on the tab header and on each venture): pick the venture, date, amount and payment currency (converted to USD), mode of payment, bank and receipt, then choose whether it is owner money or investor money:
  - *Owner money · reinvested from cash / profit held*: no new money; clears cash per books.
  - *Owner money · new paid-up capital*: also books a capital contribution, so paid-up capital rises.
  - *Investor money*: pick the investor and their placement. The form shows how much of that placement isn't yet placed and warns before it is counted twice.
- Every active venture now shows on the Ventures tab, even with nothing recorded yet.

## Initial paid-up capital (6 Oct 2026)
- **Share capital → Initial paid-up capital**: enter the shareholders' names and what each put into each venture, e.g. SK Livestock AED 35,000 and Empyrean USD 16,666 per shareholder, with dates.
- It replaces the FAMCON paid-up capital entries (the same money) with one entry per shareholder per venture, so the shareholder table shows each shareholder's % and share of equity.
- The preview compares the amounts with the owner money recorded as placed in each venture. Ticking the box records any shortfall as owner money invested, so cash per books stays at 0.
- Running it again replaces the earlier entries, so nothing is counted twice.
- **Other income → Ready to record**: Property management USD 19,000, reinvested in Solar as PKR 5,000,000 (needs the Solar venture), and AI Brands USD 6,000, used to pay investor profit. Click Record, enter the date and save. Each line disappears once it is recorded.
- New other income categories: Property management, AI brands.
- **Share capital**: there are no "brought forward" lines, because the company started in April 2026. If you pick a period that starts later, the capital and profit from before it show as "Apr 2026 to …" lines.
- **Share capital statement**: Initial paid-up capital + Profit earned + Other income = Share capital, checked against the balance sheet. Below it, a separate **Profit earned** table splits profit into: on initial paid-up capital, on other income reinvested, and on investor money, with the % of each. Portfolio's "Made up of" uses the same lines.

## New layout (6 Oct 2026)
- **Sidebar with 5 main sections**: Dashboard, Shareholders, Investors, Ventures, Other income. Everything else sits under Accounts (Financial statements, Ledger, Bank, Expenses), Analysis (Returns, Monthly, Reports) and Setup (Master data, Settings). On a phone the 5 sections become a bottom bar, and the rest are under **More**.
- **The Portfolio tab is removed.** Its content moved:
  - allocation → Dashboard
  - investor/owner split and position → Ventures
  - share capital breakdown → Shareholders → Where it is invested
  - cash per books → Shareholders
  - raised & placed → Investors
- **Dashboard** shows only: total capital deployed (share capital vs investors), share capital, investor capital, net profit % p.a., portfolio allocation by venture, and who funds each venture. At most one alert is shown.
- **Views inside each section** instead of long pages of tables:
  - Shareholders: Share capital · Shareholders · Where it is invested · Capital trail
  - Investors: Monthly profit & payments · Placements · Raised & placed
  - Ventures: Overview (one card per venture, including those at 0) · Monthly position · Accounts
- New look: indigo/violet theme, line icons, and dark mode follows the device setting.
- **Dashboard and Ventures use each venture's full position** (amount invested + profit receivable). Empyrean's compounding receivable now counts as money in the venture. Total capital deployed = Share capital + Investor capital + Investor profit payable, the same as total assets.
- **Share capital + Investor money = Total capital deployed**, always. Investor money is investor capital only; investor profit payable is shown on its own line, because it is paid separately.

## Load position workbook (6 Oct 2026)
- **Settings → Import → Load workbook**: choose the monthly *Position as at* workbook. The preview shows ventures and rates, shareholder vs investor capital, and the P&L by month. **Replace data** takes a backup, then rebuilds:
  - **Ventures**: rates from the sheet (Empyrean 6.25%/month, SK 2.5%/month, Solar 3.11%/month, Commodity 0).
  - **Share capital**: the first date is initial paid-up capital per shareholder. Later rows are profit reinvested (FAMCON accrued profits).
  - **Placements**: one per investor row and venture. FAMCON rows are left out because they are already in share capital.
  - **Monthly P&L**: venture income, other income, expenses, tax and donations. SK profit is all received; Empyrean withdrawals reduce the receivable.
  - **Investor profit**: worked out per placement and matched to the P&L "Management expenses" each month. Paid up to the month before the last.
- **Books are closed** to the last P&L month, so Run profit accruals only posts later months.
- Investors' contact, bank and payout-currency details are kept. Bank accounts, suppliers and users are untouched.
- **Initial paid-up capital** is USD 16,666 (Empyrean) + AED 35,000 (SK) per shareholder, i.e. USD 52,392.58 for both. The rest of the 1 Apr shareholder rows (USD 48,087.40) is shown as additional paid-up capital. The amounts invested are unchanged.

## Expense accruals and allocation (7 Oct 2026)
- **Expenses → Accruals**: record an expense before it is paid. It shows in the P&L in that month and as an **Accrued expenses** liability on the balance sheet until it is paid.
  - **Add accrual** records a single accrual. Tick *Repeat this accrual* to make it recurring.
  - **Recurring schedules** can be monthly, quarterly, half-yearly or annual, with an optional end month. Due accruals up to last month post automatically at sign-in, or use **Post due**. Schedules can be edited, paused or deleted; posted accruals stay.
  - **Mark paid**, one at a time or for selected accruals together, records the payment (date, mode, bank, receipt) and clears the liability. Part payments are supported.
- **Allocate to**: every expense, accrual and schedule is allocated to a venture or to **Head office**. Expenses paid → **By allocation** totals paid and accrued expenses for the period.
- Accrual months on or before the books-closed month are skipped.

## PSX, commodity trading and the allocation chart (7 Oct 2026)
- **Ventures → Shares & commodities**: holdings for a share portfolio (PSX) or for commodity trading (units in Bags or Tons). Buy, sell and dividend entries record date, share or commodity, quantity, price, fees, amount in PKR and the USD booked, plus payment details and a receipt.
  - **Holdings table**: share, quantity held, average purchase price, amount purchased, quantity sold, profit realised, market value at the reporting date, and unrealised profit.
  - **Market value** defaults to cost. Edit it and save at the period end date, or load it from a report. Unrealised profit is shown here but not posted to the P&L. Realised profit on a sale (proceeds less average cost) and dividends go to venture profit.
  - **Upload report to reconcile**: an .xlsx or .csv broker or stock report. Quantities are compared per share (matches / differs / missing), market prices can be updated from it, and the report file is kept.
  - Investment in the venture without a share name shows as "Not yet split by share".
- **Listed Equities** is renamed to **PSX** and set up as a share portfolio automatically at the next sign-in.
- **Dashboard**: a second allocation chart shows percentages only.
- **PSX securities dropdown**: Buy in a share portfolio offers about 365 PSX-listed securities. You can type a symbol or a company name, and the company name shows under the symbol in holdings. **PSX list** updates it, either from the PSX data portal (if the browser can reach it) or from an uploaded file with Symbol and Name columns. New symbols are added and none are removed. You can still type a symbol that isn't in the list.
- **Ventures → Placements**: for each venture (or all ventures together), every placement with its date, who it came from (investor, shareholder, reinvested profit or other income), investor money or share capital, the rate (investor's agreed rate or the venture rate), mode of payment, bank, the original currency amount and a running invested balance. Filter by placements in, withdrawals, profit entries or all entries. **Click any row to edit it**: investor rows open the investor placement, the rest open the entry. Each venture card has a **Placements** button.
- **Placements are shown as tranches**: one line per venture per date with the total placed (investor money, share capital, average agreed investor rate, invested balance). Click a tranche to see the entries that made it up and edit any of them.

## Export every page; Returns and Monthly tabs removed (7 Oct 2026)
- **⤓ Excel / ⤓ PDF** at the top of every page download exactly what is on screen for the current tab and view. That covers the summary figures, every table, venture cards and chart breakdowns, with one Excel sheet per table and numbers kept as numbers.
- **Returns and Monthly tabs are removed** because they repeated other tabs. Their unique parts moved:
  - **Investors → Placements** now shows profit accrued to date, paid to date, payable and an **accrual check** (on track / under / over the agreed rate).
  - **Financial statements → By month** now has **cumulative net profit** and **cash received** rows.
- **Reports & email** (the monthly investor report emailed as Excel + PDF) stays in the sidebar.
- **Investors at a glance**: cards at the top of the Investors tab show each investor's name, capital placed, average agreed rate, profit to date and amount due, largest first (top 8, then "Show all"). Click a card for that investor's month-by-month view: KPIs, an interactive chart of monthly profit accrued vs paid, and capital by month (new placements highlighted). **Show placements** jumps to their rows.

## Phone app (installable web app) (7 Oct 2026)
- **New files to upload:** `manifest.webmanifest`, `sw.js`, the `icons/` folder (5 PNGs) and the updated `vercel.json`, next to index.html.
- **Install**: on iPhone, open the site in Safari → Share → **Add to Home Screen**. On Android, open it in Chrome → ⋮ → **Install app**. It opens full screen with the Future Axis icon and uses the same login and data.
- **Quick entry** is the phone home screen (and the start screen for Editors on a phone). It has large buttons for expenses (with a receipt photo from the camera), accruals, paying investors, other income, venture withdrawals, investments, paying accruals and bank statements, a to-do list (investor profit due, accruals to pay or post) and recent entries.
- **Offline**: the app shell is cached so it opens quickly, but data always comes live from Supabase and nothing is stored on the phone. `index.html` and `sw.js` are served with no-cache headers, so updates appear on the next open.
- Give the accountant the **Editor** role (Settings → Users).
- **Scan receipt** (Quick entry, and at the top of Add expense): take a photo or choose one. The phone reads the receipt and fills in date, amount, currency, merchant (with VAT), invoice number, category and supplier (if it's in master data). Filled fields are highlighted green. Check them, then save; the photo is attached as the receipt. Typing everything in by hand still works.
  - Reading happens in the browser with Tesseract (open-source OCR, loaded from cdn.jsdelivr.net), so nothing is sent to an outside service. The first scan downloads the reader (a few MB), and later scans are faster.
  - PKR receipts: the PKR amount goes into "PKR received by supplier"; enter the USD or AED paid.

## IBKR stocks & ETFs (9 Oct 2026)
- New holdings type **IBKR stocks & ETFs** (USD), working like PSX: Buy / Sell / Dividend, average cost, realised and unrealised gain, market value (defaults to cost, editable), report reconciliation.
- A venture named "Interactive Brokers" / "IBKR" is set up automatically; otherwise Ventures → Shares & commodities → Create IBKR portfolio (or Use an existing venture).
- Symbol list: `ibkr-symbols.txt` (11,998 US-listed stocks and ETFs on NASDAQ, NYSE, NYSE Arca, NYSE American, Cboe, plus popular LSE UCITS ETFs). Loaded only when needed. Add more with **IBKR list → upload** (any file with a Symbol column).
- Reconcile by uploading the IBKR Activity Statement CSV (Open Positions section is read) or a Flex/positions export.
- Buy box searches by symbol or company name (PSX too), showing the top matches.
