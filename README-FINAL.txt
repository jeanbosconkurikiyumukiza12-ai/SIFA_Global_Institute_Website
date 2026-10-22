SIFA GLOBAL INSTITUTE — IMPLEMENTATION BUILD

Admissions are CLOSED by default. This package includes new public-application, staff-review, billing, scholarship, protected-learning and certificate-verification code, but it is NOT deployed to the live Supabase/Vercel project by this archive alone.

READ FIRST:
- SIFA-FINAL-IMPLEMENTATION-GUIDE.md
- FINAL-REVIEW-STATUS.txt
- FULL-TEST-CHECKLIST.txt

IMPORTANT SAFETY NOTES:
1. Do not run the existing student portal setup SQL scripts blindly. Two account-deletion SQL files differ.
2. SIFA-BACKEND-FOUNDATION-DRAFT.sql is a draft migration. Review it against a backup and test it in a separate Supabase staging project first.
3. Do not run ADMISSIONS-SETUP.sql; admissions are intentionally closed.
4. Never put SUPABASE_SERVICE_ROLE_KEY or other secrets in browser files, GitHub, screenshots, or chat.
5. Create the first staff role only after verifying the intended Auth user ID. Instructions are in SIFA-FINAL-IMPLEMENTATION-GUIDE.md.
6. Do not publish SIFA bank/mobile-money details until the owner confirms authorization for business use.

LOCAL PREVIEW:
Extract the archive, open the root folder in VS Code, start Live Server on index.html, then check the public pages. Public application submission will remain closed until the staging backend is deployed and configured.

CURRENT LIVE WEBSITE AND REPOSITORY WERE NOT MODIFIED BY PREPARING THIS ARCHIVE.
