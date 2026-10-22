# SIFA Global Institute — implementation package

This package extends the supplied static website with a backend workflow foundation. It is a **deployment candidate, not a claim that the live service is already deployed or verified**. The live Supabase schema, RLS policies, auth redirect settings, email delivery, and payment evidence must be validated in a staging project first.

## Included in this build

- Public application submission through a server-side Edge Function; application intake remains closed by default.
- Server-side validation, generated reference numbers, private supporting-document storage, and scholarship-request record creation.
- Restricted staff console for application decisions, document access through 60-second signed URLs, account linking, enrollment creation, scholarship decisions, monthly invoice creation, receipt review, and certificate issuance.
- Student billing page for viewing own invoices and securely submitting receipts.
- Student Payments page displays the owner-defined fee schedule: 10,000 RWF/month, monthly due date on the 1st, 14-day grace period, manual monthly renewal, Rwanda Mobile Money and Ziraat Bank transfer as payment methods, partial monthly-fee scholarships, and an optional 5,000 RWF certificate fee. Public payment details are displayed on the Fees & Scholarships page; confirm recipient identity and invoice amount before paying.
- Server-side receipt review; receipt upload does not grant access. An authorized reviewer must approve it.
- Protected learning page that checks enrollment, verified monthly invoice status, the 14-day grace period, and an explicit temporary access exception before returning the configured live-class URL.
- Public certificate verification using a narrow RPC that returns only certificate code, display name, program, issue date, and registry status.
- Student Portal integration to display public applications after an administrator links the application to the student's verified account.
- Audit entries for staff decisions and sensitive document access.

## Owner-confirmed commercial rules encoded here

- Standard monthly course fee is 10,000 RWF. The admin can enter the invoice currency and amount; do not guess a TRY exchange rate.
- The optional certificate fee is 5,000 RWF and is never discounted by scholarships.
- Approved scholarships discount monthly course fees only.
- Monthly invoice creation is manual; no automatic recurring charges are implemented.
- The due date is the first day of the invoiced month and the access grace period is 14 days.
- Live-class URL is private and returned only after server-side access checks.
- Application acceptance, scholarship approval, payment approval, and course access are separate decisions.

## Deployment order — use staging first

1. Make a backup of the current Supabase project and inspect existing tables, RLS policies, storage buckets, auth URL configuration, and installed SQL functions. The two existing account-deletion SQL scripts in this repository are not interchangeable; do not run either as part of this workflow.
2. Create a separate Supabase staging project. Review `SIFA-BACKEND-FOUNDATION-DRAFT.sql` against the actual schema before running it. It is a migration draft, not an automatically safe production script.
3. Deploy Edge Functions from this repository using the Supabase CLI. The project reference in `supabase/config.toml` matches the source configuration but must still be confirmed in the dashboard before deployment.
4. Configure function secrets in Supabase. Required settings:
   - `SUPABASE_SERVICE_ROLE_KEY`: server-side only; never commit or paste it into browser files.
   - `SIFA_ALLOWED_ORIGINS`: comma-separated exact origins, e.g. the production Vercel origin and the local test origin only if required. Do not use `*`.
   - `SIFA_APPLICATIONS_OPEN=false` until the full application workflow passes tests.
   - `SIFA_OPEN_PROGRAMS`: exact program names, initially empty.
   - `SIFA_LIVE_CLASS_URL`: the private meeting URL; never put it in public HTML or GitHub.
   Supabase supplies `SUPABASE_URL`; the function also uses the project service key. Never expose service-role credentials in the website.
5. Create the first administrator by signing up through Supabase Auth, verifying that account, then use a reviewed SQL statement to add that exact `auth.users.id` to `public.sifa_staff_roles` as `administrator`. Do not grant staff roles based only on an email address or a browser request. Restrict who can access the SQL Editor.
6. Test the complete workflow in staging: public application, file rejection/size limits, no anonymous direct table reads, staff role denial, application decision, student account linking, enrollment, monthly invoice, scholarship discount, receipt upload, rejected and approved receipts, 14-day grace boundary, suspended/re-activated access, certificate fee, certificate issuance, and public verification.
7. Test password recovery with a fresh link and verify redirect allow-list settings for the actual Vercel domain. Do not reuse old recovery links. Confirm email deliverability in the live email provider.
8. Only after all tests pass should admissions be enabled. Set `SIFA_APPLICATIONS_OPEN=true`, list only approved program names in `SIFA_OPEN_PROGRAMS`, and change `window.SIFA_SETTINGS.applicationsOpen` / `openPrograms` in `supabase-config.js` in the same deployment. This build intentionally leaves admissions closed.
9. Deploy the tested files through GitHub/Vercel, then repeat smoke tests on the production domain. Do not publish payment-account details until the owner has confirmed that each account is authorized for SIFA business use.

## Edge Function deployment

From this project root, after installing and authenticating the Supabase CLI and confirming the project reference:

```sh
supabase functions deploy public-application --no-verify-jwt
supabase functions deploy sifa-admin-api
supabase functions deploy submit-payment-receipt
supabase functions deploy sifa-student-billing
supabase functions deploy sifa-learning-access
```

The CLI commands deploy code only. They do not run the SQL migration or enable admissions automatically.

## Initial administrator bootstrap (manual, after staging migration)

First sign in to the intended administrator account and verify the email. Copy that exact user UUID from Supabase Auth, inspect it carefully, and run only in the staging project first:

```sql
insert into public.sifa_staff_roles (user_id, role, active)
values ('PASTE-VERIFIED-AUTH-USER-UUID-HERE', 'administrator', true)
on conflict (user_id) do update set role = excluded.role, active = true;
```

Replace the placeholder locally; do not send the user UUID or any secret in chat. A user with administrator role can assign roles, so protect this account with a strong password and MFA where available.

## Important current limits

- No code in this package has been deployed to Supabase, GitHub, or Vercel from this chat.
- SQL syntax and browser JavaScript are statically checked locally, but Supabase/Deno compilation and database behavior require staging deployment.
- Payment approval is manual evidence review; this does not automatically reconcile transfers with a bank or mobile-money provider.
- Student account linking requires the applicant to create and verify a portal account using the same email address.
- A public web page cannot stop an authorized student from copying a meeting link after receiving it. Use Google Meet host controls and participant checks.
- The system does not initiate real payments, send admissions decision emails, or automatically renew monthly invoices.
- The certificate registry verifies records entered by authorized staff; it does not represent external accreditation.
