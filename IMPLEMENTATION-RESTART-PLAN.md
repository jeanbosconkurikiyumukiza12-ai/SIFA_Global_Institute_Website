# SIFA Global Institute — Implementation Restart Plan

This file is a work plan, not proof that any live service has been changed. The current repository is a static HTML/JavaScript site backed by Supabase Auth, Postgres, and Storage. Live Supabase settings and schema must be inspected by the owner before any migration is run.

## Delivery rule

Work in small, testable increments. Preserve existing pages and branding. Keep admissions closed until the application pipeline and admin review are tested. Never commit Supabase secret/service-role keys, payment receipts, identity documents, or private class links.

## Required implementation order

### 1. Data and access security (blocker)
- Inspect live tables, constraints, functions, triggers, RLS policies, Storage policies, and Auth redirect allow-list.
- Resolve the two conflicting account-deletion SQL definitions before any migration.
- Prevent students from setting application status, admission decisions, scholarship decisions, payment state, enrollment state, or certificate state.
- Introduce explicit administrator/coordinator roles that cannot be granted by a student through the browser.
- Add audit records for all privileged decisions.
- Test anonymous, student A, student B, coordinator, administrator, and unauthenticated requests against each table and Storage bucket.

### 2. Public application intake
- Public application page must work without requiring a student account.
- Submit through a server-side Supabase Edge Function, not a direct anonymous insert into the existing authenticated `applications` table.
- Validate fields, allowed program/cohort, consent, file type/size, and admissions-open configuration server-side.
- Generate the reference number on the server; force initial status to `Submitted`; ignore client-supplied administrative fields.
- Store documents privately, use random object names, and bind each document to the intake record. Do not return public storage URLs.
- Add rate limiting / abuse protection and clear duplicate-submission handling.
- Account creation can be offered after submission; linking an intake to a student account must verify the email and avoid exposing another applicant's record.

### 3. Admin / coordinator workspace
- Protected admin page with server-authorized role checks.
- Application queue, detail view, private document access, notes, request-information action, accept/reject decisions, and decision history.
- Every decision writes actor, timestamp, reason, and prior/new state to an audit log.
- Students may read only their own linked records; no client-side role check alone is trusted.

### 4. Fees, receipts, renewals, scholarships, and access
- Record invoices/fee periods separately from receipts and approval decisions.
- Standard monthly fee: 10,000 RWF; first-month introduction discount: 5,000 RWF for the first month only; monthly due date: day 1; grace period: 14 days; course duration: 3 months.
- Manual receipt review; uploading a receipt never grants access.
- Partial scholarships reduce monthly fees only; certificate fee remains separate.
- Enrollment access derives only from an approved payment, valid approved scholarship/waiver, or documented authorized exception.
- Monthly renewal is manual; no automatic billing.
- Do not publish bank/mobile-money details until the owner confirms permission and accuracy.

### 5. Protected learning portal
- Show live-class joining information only after a server-side authorization check.
- Never put a permanent meeting URL in public HTML or client configuration.
- Add host-side meeting controls and an operational process for removing unauthorized participants.
- Decide and implement grace-expiry behavior, suspension, and reactivation before enabling access checks.

### 6. Certificate issuance and public verification
- Issue a certificate record only after completion requirements and (if requested) the 5,000 RWF certificate fee are approved.
- Generate a unique non-guessable verification code; store revocation/status and issue date.
- Public verification reveals only the minimum necessary fields and must not disclose private student documents or personal details.
- Keep the public page clearly marked inactive until the registry is deployed and tested.

### 7. Password recovery and regression tests
- Test a fresh single-use recovery link on the deployed Vercel origin and confirm Supabase Auth redirect settings.
- Test expired, reused, malformed, and valid links; successful password update; login after reset; and email delivery.
- Regression-test mobile navigation, account signup/login/logout, profile update, application submission and reference display, withdrawal, account deletion, and email verification.

## Current owner decisions already recorded
- Applications should ultimately be public without login; the learning portal requires login and authorization.
- Keep admissions closed until backend tests pass.
- Live online classes only; the meeting link is protected learning-portal content.
- No paid infrastructure is assumed; prefer free-tier-compatible options.

## Decisions still required before final production behavior
- Scholarship eligibility criteria and discount percentages.
- Refund/cancellation rules.
- What happens after the 14-day grace period and how reactivation works.
- Whether the first-month discount applies once per course or once per account.
- Cohort start dates, billing periods, and currency conversion rules for Türkiye payments.
- Completion criteria and certificate issuance workflow.
- Authorized administrator/coordinator identities and role assignment process.

## Status
- Source review and a local review archive exist.
- No live Supabase schema, Auth settings, Storage policies, GitHub repository, or Vercel deployment has been changed from this workspace.
- This plan must be converted into migration/function/UI code and tested in a separate staging project before production rollout.
