# SIFA Student Classroom — Implementation and Deployment Notes

## What this change adds
- A student classroom with a live-class section and separate Books/PDFs, Lessons/Notes, Assignments, and Announcements sections.
- A restricted staff manager for PDF uploads (up to 20 MB), course assignment, descriptions, drafts/publishing, unpublishing, and permanent deletion.
- Private Supabase Storage. The browser does not receive the service-role key. Signed download links last 180 seconds.
- Server-side checks for the current user's Supabase session and active SIFA staff role. Student material listings require an active enrollment plus verified/waived current monthly invoice, grace period, or unexpired access exception.
- Only published materials matching the student's exact enrollment program are returned.

## Not deployed yet
These are source-code and migration changes only. Do not consider the classroom live until the migration and Edge Function are deployed and the test checklist below passes. No production database changes were run by this package.

## Before deployment
1. Back up the current site and Supabase database/schema.
2. Review `student-classroom-schema.sql`.
3. In Supabase SQL Editor, run the schema only after you explicitly approve. It creates `sifa_learning_materials` and the private `sifa-learning-materials` bucket. It does not change existing enrollment, invoice, or student-auth tables.
4. Deploy Edge Function `sifa-classroom-api` using Supabase CLI.
5. Confirm the Edge Function secrets are set in Supabase: `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `SIFA_ALLOWED_ORIGINS`, and (when the live class is ready) `SIFA_LIVE_CLASS_URL`. The service-role key must remain server-side and must never be copied into HTML or JavaScript.
6. Set `SIFA_ALLOWED_ORIGINS` to the exact origins used by the site, for example the production Vercel origin and the local Live Server origin. Do not include paths or trailing slashes. Add localhost/127.0.0.1 only if you need local development.
7. Confirm the staff accounts that should upload materials have active rows in `public.sifa_staff_roles` with role `administrator`, `coordinator`, or `instructor`. Do not give staff roles to student accounts.
8. Make sure the program name entered by staff exactly matches the `program` value in `public.sifa_enrollments`.

## Deployment command
From the website repository root, after reviewing the target Supabase project:
```bash
supabase functions deploy sifa-classroom-api --project-ref pdzspvwhkxdmuynvpjsy
```
Do not paste a service-role key into this repository. Set function secrets through Supabase's secret management interface or CLI secret command.

## Manual test checklist
- [ ] Authorized staff can sign in at `sifa-classroom-manager.html`.
- [ ] A normal student account receives a 403 and cannot list/upload/publish/delete staff materials.
- [ ] Staff can upload a small PDF, save as draft, publish it, unpublish it, and delete it.
- [ ] An authorized student with active access sees only published PDFs for their exact program.
- [ ] A student with no active access cannot list materials or receive download links.
- [ ] A student from a different program cannot see the first program's files.
- [ ] Signed download URL expires after a short period.
- [ ] The live-class link is absent until `SIFA_LIVE_CLASS_URL` is configured and the student is authorized.
- [ ] Test file-size limits, non-PDF rejection, expired sessions, mobile layout, and local/production CORS origins.
- [ ] Confirm existing student sign-in, application dashboard, payments, and staff console still work.

## Important limitations
- Uploads are currently PDF-only and capped at 20 MB. Large books should be compressed or split.
- Announcements are represented as PDF notices in this first implementation; editable text announcements are not included yet.
- This does not itself create enrollments, approve payments, or authorize access exceptions. Those remain in the existing SIFA workflows.
