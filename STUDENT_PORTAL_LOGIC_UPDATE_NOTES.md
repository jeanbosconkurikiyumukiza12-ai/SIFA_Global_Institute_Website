# SIFA Student Portal Logic Update

## UI changes
- The logged-in student dashboard now presents only two primary destinations: Application and SIFA Classroom.
- Application details are shown only after clicking Application.
- The existing account/authentication logic and the application form/status data elements remain in the page for compatibility.
- Classroom continues to use `student-learning.html` and the server-side access check.

## Important deployment status
This is a source-code update only. It has not been deployed to Vercel or Supabase.
If the classroom Edge Function is absent/unavailable, the classroom page now states that service is unavailable and that payment status has not been determined. It does not treat a backend failure as proof of non-payment.

## Payment and access logic that must be completed/verified on the backend
1. Verify authenticated user from the Supabase session token server-side.
2. Look up the student's enrollment and the authoritative invoice/receipt state.
3. If payment is pending/unconfirmed, show the payment page/status and keep learning materials blocked.
4. If payment is confirmed (or a valid approved scholarship/exception applies), authorize the enrolled program.
5. On backend error, fail closed for private materials but show an explicit service error, never "unpaid".
6. Upload PDF files to private storage; only published files for the authorized program are returned.
7. Never rely on browser-only UI checks to protect materials.

Do not run `student-classroom-schema.sql` against production until reviewed and explicitly approved. The new Edge Function also needs to be checked against the actual current database schema before deployment.
