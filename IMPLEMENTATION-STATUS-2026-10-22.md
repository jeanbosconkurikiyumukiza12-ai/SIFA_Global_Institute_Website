# SIFA implementation status — 22 October 2026

## New local source artifacts in this build
- `IMPLEMENTATION-RESTART-PLAN.md`: ordered implementation and test plan covering the agreed system.
- `SIFA-BACKEND-FOUNDATION-DRAFT.sql`: additive draft schema for staff roles, audit log, public applications, document metadata, scholarship decisions, enrollments, fee invoices, receipt review, and certificate registry. Includes restrictive RLS policies and intentionally grants no anonymous insert access.
- `supabase/functions/public-application/index.ts`: server-side public intake Edge Function source. It defaults to closed unless `SIFA_APPLICATIONS_OPEN=true`, restricts allowed origins, validates fields, ignores client-supplied status/IDs/decision fields, generates a server-side reference, and writes only to the separate public-intake table.

## Not yet complete or verified
- These new files have not been deployed to Supabase and the SQL has not been run.
- The existing `apply.html`/`student-application.js` form has not yet been rewired to this Edge Function.
- Public document uploads need a private, validated upload workflow; do not treat the existing authenticated-only upload flow as public-ready.
- Admin UI and secure decision functions are not yet implemented.
- Payment receipt upload/review UI, invoice creation/renewal logic, scholarship approval UI, enrollment access enforcement, protected live-class page, certificate issuance/verification RPC, and complete recovery/security regression tests remain outstanding.
- No live website, Supabase, GitHub, or Vercel configuration has been changed.

## Critical deployment prerequisites
1. Back up and inspect the live Supabase schema and policies.
2. Test the draft SQL in a separate staging project; resolve compatibility and policy tests before any production migration.
3. Deploy the Edge Function with server-side secrets and exact allowed-origin configuration.
4. Keep admissions closed until form integration, private document upload, abuse controls, and role-based admin review have passed end-to-end tests.


## Public Fees, Payments & Scholarships hub update
- `student-payments.html` is now a public information page; fee and scholarship rules, safe payment guidance, FAQ and relevant internal links are readable without login.
- Private invoices and receipt submission remain behind account verification. Receipt upload is not payment approval or automatic course access.
- Scholarship status is stated as currently closed; no unsupported scholarship percentage or recipient payment details are published.
- Main navigation now links to Fees & Scholarships across pages that contain the shared navigation.
- This is a source change only; live Supabase/deployment behavior has not been verified.
