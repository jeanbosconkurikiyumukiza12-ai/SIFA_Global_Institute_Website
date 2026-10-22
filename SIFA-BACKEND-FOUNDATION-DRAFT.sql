-- SIFA Global Institute backend foundation (DRAFT — DO NOT RUN IN PRODUCTION YET)
-- Prepared for review against the live Supabase schema. This is intentionally
-- additive; it does not alter existing application policies or expose documents.
-- Run only after backup, schema diff, and staging validation.

begin;
create extension if not exists pgcrypto;

-- Privileged roles are assigned only by a trusted administrator through the
-- Supabase dashboard/SQL Editor, never by a browser-facing student workflow.
create table if not exists public.sifa_staff_roles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('administrator','coordinator','finance_reviewer','instructor')),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  created_by uuid references auth.users(id) on delete set null
);

create or replace function public.sifa_has_staff_role(allowed_roles text[])
returns boolean
language sql stable security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.sifa_staff_roles r
    where r.user_id = (select auth.uid())
      and r.active is true
      and r.role = any (allowed_roles)
  );
$$;
revoke all on function public.sifa_has_staff_role(text[]) from public;
grant execute on function public.sifa_has_staff_role(text[]) to authenticated;

create table if not exists public.sifa_audit_log (
  id uuid primary key default gen_random_uuid(),
  actor_user_id uuid references auth.users(id) on delete set null,
  action text not null,
  entity_type text not null,
  entity_id uuid,
  before_data jsonb,
  after_data jsonb,
  reason text,
  created_at timestamptz not null default now()
);
create index if not exists sifa_audit_entity_idx on public.sifa_audit_log(entity_type, entity_id, created_at desc);

-- Separate public intake from the existing applications table, which requires
-- an authenticated user_id. The public page must call a server-side Edge
-- Function that validates submissions and writes to this table with a trusted
-- server credential; do NOT grant anon direct INSERT on this table.
create table if not exists public.sifa_public_applications (
  id uuid primary key default gen_random_uuid(),
  application_ref text not null unique,
  full_name text not null,
  email text not null,
  phone text not null default '',
  country text not null default '',
  program text not null,
  payload jsonb not null default '{}'::jsonb,
  status text not null default 'Submitted'
    check (status in ('Submitted','Under Review','Needs Information','Accepted','Rejected','Withdrawn')),
  linked_user_id uuid references auth.users(id) on delete set null,
  submitted_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  decided_at timestamptz,
  decided_by uuid references auth.users(id) on delete set null,
  decision_reason text
);
create index if not exists sifa_public_apps_status_idx on public.sifa_public_applications(status, submitted_at desc);
create index if not exists sifa_public_apps_email_idx on public.sifa_public_applications(lower(email));

-- Hash-only rate-limit counters for the public intake endpoint; no raw IP/email is stored.
create table if not exists public.sifa_application_rate_limits (
  key_hash text primary key,
  window_started_at timestamptz not null,
  attempt_count integer not null check (attempt_count >= 0),
  updated_at timestamptz not null default now()
);
create or replace function public.sifa_allow_public_application(p_email_hash text, p_ip_hash text default null)
returns boolean language plpgsql security definer set search_path = '' as $$
declare v_now timestamptz := now(); v_email_count integer; v_ip_count integer := 0;
begin
  insert into public.sifa_application_rate_limits(key_hash,window_started_at,attempt_count,updated_at)
  values ('email:' || p_email_hash,v_now,1,v_now)
  on conflict (key_hash) do update set
    window_started_at = case when public.sifa_application_rate_limits.window_started_at < v_now - interval '1 hour' then v_now else public.sifa_application_rate_limits.window_started_at end,
    attempt_count = case when public.sifa_application_rate_limits.window_started_at < v_now - interval '1 hour' then 1 else public.sifa_application_rate_limits.attempt_count + 1 end,
    updated_at = v_now
  returning attempt_count into v_email_count;
  if p_ip_hash is not null and length(p_ip_hash) > 0 then
    insert into public.sifa_application_rate_limits(key_hash,window_started_at,attempt_count,updated_at)
    values ('ip:' || p_ip_hash,v_now,1,v_now)
    on conflict (key_hash) do update set
      window_started_at = case when public.sifa_application_rate_limits.window_started_at < v_now - interval '1 hour' then v_now else public.sifa_application_rate_limits.window_started_at end,
      attempt_count = case when public.sifa_application_rate_limits.window_started_at < v_now - interval '1 hour' then 1 else public.sifa_application_rate_limits.attempt_count + 1 end,
      updated_at = v_now
    returning attempt_count into v_ip_count;
  end if;
  return v_email_count <= 3 and (p_ip_hash is null or v_ip_count <= 10);
end; $$;
revoke all on function public.sifa_allow_public_application(text,text) from public;
grant execute on function public.sifa_allow_public_application(text,text) to service_role;

create table if not exists public.sifa_application_documents (
  id uuid primary key default gen_random_uuid(),
  public_application_id uuid references public.sifa_public_applications(id) on delete cascade,
  existing_application_id uuid references public.applications(id) on delete cascade,
  storage_bucket text not null default 'student-documents',
  storage_path text not null,
  original_filename text not null,
  content_type text not null,
  byte_size bigint not null check (byte_size > 0 and byte_size <= 10485760),
  uploaded_at timestamptz not null default now(),
  check ((public_application_id is not null) <> (existing_application_id is not null)),
  unique(storage_bucket, storage_path)
);

create table if not exists public.sifa_scholarship_decisions (
  id uuid primary key default gen_random_uuid(),
  public_application_id uuid references public.sifa_public_applications(id) on delete cascade,
  application_id uuid references public.applications(id) on delete cascade,
  decision text not null check (decision in ('pending','approved','rejected','withdrawn')) default 'pending',
  monthly_discount_percent numeric(5,2) not null default 0 check (monthly_discount_percent >= 0 and monthly_discount_percent <= 100),
  starts_on date,
  ends_on date,
  reason text,
  decided_by uuid references auth.users(id) on delete set null,
  decided_at timestamptz,
  created_at timestamptz not null default now(),
  check ((public_application_id is not null) <> (application_id is not null)),
  check (ends_on is null or starts_on is null or ends_on >= starts_on)
);

create table if not exists public.sifa_enrollments (
  id uuid primary key default gen_random_uuid(),
  student_user_id uuid not null references auth.users(id) on delete cascade,
  public_application_id uuid references public.sifa_public_applications(id) on delete set null,
  application_id uuid references public.applications(id) on delete set null,
  program text not null,
  status text not null default 'pending_payment' check (status in ('pending_payment','active','suspended','completed','withdrawn')),
  start_date date,
  end_date date,
  access_exception_reason text,
  access_exception_approved_by uuid references auth.users(id) on delete set null,
  access_exception_expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (not (public_application_id is not null and application_id is not null))
);
create index if not exists sifa_enrollments_user_idx on public.sifa_enrollments(student_user_id, status);

create table if not exists public.sifa_fee_invoices (
  id uuid primary key default gen_random_uuid(),
  enrollment_id uuid not null references public.sifa_enrollments(id) on delete cascade,
  period_start date not null,
  period_end date not null,
  invoice_type text not null default 'monthly_course' check (invoice_type in ('monthly_course','certificate_fee')),
  currency text not null check (currency in ('RWF','TRY')),
  base_amount numeric(12,2) not null check (base_amount >= 0),
  discount_amount numeric(12,2) not null default 0 check (discount_amount >= 0),
  amount_due numeric(12,2) generated always as (greatest(base_amount - discount_amount, 0)) stored,
  due_date date not null,
  status text not null default 'unpaid' check (status in ('unpaid','receipt_submitted','paid','waived','overdue','cancelled')),
  created_at timestamptz not null default now(),
  check (period_end >= period_start),
  check (discount_amount <= base_amount)
);

create table if not exists public.sifa_payment_receipts (
  id uuid primary key default gen_random_uuid(),
  invoice_id uuid not null references public.sifa_fee_invoices(id) on delete cascade,
  student_user_id uuid not null references auth.users(id) on delete cascade,
  storage_path text not null unique,
  payment_method text not null check (payment_method in ('Rwanda Mobile Money','Ziraat Bank Transfer','Other approved method')),
  claimed_amount numeric(12,2) not null check (claimed_amount > 0),
  claimed_currency text not null check (claimed_currency in ('RWF','TRY')),
  transaction_reference text,
  status text not null default 'pending_review' check (status in ('pending_review','approved','rejected')),
  reviewer_user_id uuid references auth.users(id) on delete set null,
  reviewed_at timestamptz,
  reviewer_note text,
  submitted_at timestamptz not null default now()
);
create index if not exists sifa_receipts_review_idx on public.sifa_payment_receipts(status, submitted_at desc);

create table if not exists public.sifa_certificate_registry (
  id uuid primary key default gen_random_uuid(),
  certificate_code text not null unique,
  enrollment_id uuid not null references public.sifa_enrollments(id) on delete restrict,
  student_display_name text not null,
  program text not null,
  issued_on date not null default current_date,
  status text not null default 'active' check (status in ('active','revoked','replaced')),
  issued_by uuid references auth.users(id) on delete set null,
  revoked_at timestamptz,
  revocation_reason text,
  created_at timestamptz not null default now()
);
create index if not exists sifa_cert_code_idx on public.sifa_certificate_registry(certificate_code);

-- Atomic receipt decision: invoice, enrollment and audit state change together.
create or replace function public.sifa_review_payment_receipt(p_receipt_id uuid, p_status text, p_reviewer uuid, p_note text default null)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_receipt public.sifa_payment_receipts%rowtype; v_invoice public.sifa_fee_invoices%rowtype; v_now timestamptz := now();
begin
  if p_status not in ('approved','rejected') then raise exception 'Invalid receipt decision'; end if;
  select * into v_receipt from public.sifa_payment_receipts where id = p_receipt_id for update;
  if not found then raise exception 'Receipt not found'; end if;
  if v_receipt.status <> 'pending_review' then raise exception 'Receipt has already been reviewed'; end if;
  select * into v_invoice from public.sifa_fee_invoices where id = v_receipt.invoice_id for update;
  if not found then raise exception 'Invoice not found'; end if;
  if p_status = 'approved' then
    if v_invoice.status in ('paid','waived','cancelled') then raise exception 'Invoice does not accept receipt approval'; end if;
    update public.sifa_fee_invoices set status = 'paid' where id = v_invoice.id;
    update public.sifa_enrollments set status = 'active', updated_at = v_now
      where id = v_invoice.enrollment_id and status in ('pending_payment','suspended');
  else
    update public.sifa_fee_invoices set status = 'unpaid' where id = v_invoice.id and status = 'receipt_submitted';
  end if;
  update public.sifa_payment_receipts set status = p_status, reviewer_user_id = p_reviewer,
    reviewed_at = v_now, reviewer_note = nullif(trim(coalesce(p_note,'')), '') where id = v_receipt.id;
  insert into public.sifa_audit_log(actor_user_id,action,entity_type,entity_id,before_data,after_data,reason)
  values (p_reviewer,'payment_receipt_review','payment_receipt',v_receipt.id,
    jsonb_build_object('receipt_status',v_receipt.status,'invoice_status',v_invoice.status),
    jsonb_build_object('receipt_status',p_status,'invoice_id',v_invoice.id,'invoice_status',case when p_status='approved' then 'paid' else 'unpaid' end),p_note);
  return jsonb_build_object('id',v_receipt.id,'invoice_id',v_receipt.invoice_id,'status',p_status,'reviewed_at',v_now);
end; $$;
revoke all on function public.sifa_review_payment_receipt(uuid,text,uuid,text) from public;
grant execute on function public.sifa_review_payment_receipt(uuid,text,uuid,text) to service_role;

-- Default deny for all new workflow tables. Public verification is handled by
-- a narrow RPC defined below; no public table SELECT is granted for this registry.
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'sifa_staff_roles','sifa_audit_log','sifa_public_applications','sifa_application_rate_limits',
    'sifa_application_documents','sifa_scholarship_decisions','sifa_enrollments',
    'sifa_fee_invoices','sifa_payment_receipts','sifa_certificate_registry'
  ] LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t);
  END LOOP;
END $$;

-- Staff role table: a user can see only their own role; only administrators
-- can manage role assignments. A separate trusted bootstrap step is required.
create policy "staff can view own role" on public.sifa_staff_roles
for select to authenticated using (user_id = auth.uid());
-- Role changes are performed only through a trusted database administrator;
-- the browser has no direct INSERT/UPDATE/DELETE policy for role assignments.

-- Audit log: privileged staff can read; direct browser inserts/updates/deletes
-- are not granted. Trusted server functions should append audit rows.
create policy "staff read audit log" on public.sifa_audit_log
for select to authenticated using (public.sifa_has_staff_role(array['administrator','coordinator','finance_reviewer']));

create policy "staff review public applications" on public.sifa_public_applications
for select to authenticated using (public.sifa_has_staff_role(array['administrator','coordinator']));
create policy "students view their linked public applications" on public.sifa_public_applications
for select to authenticated using (linked_user_id = (select auth.uid()));
grant select on public.sifa_public_applications to authenticated;

create policy "staff read application document metadata" on public.sifa_application_documents
for select to authenticated using (public.sifa_has_staff_role(array['administrator','coordinator']));

create policy "staff read scholarship decisions" on public.sifa_scholarship_decisions
for select to authenticated using (public.sifa_has_staff_role(array['administrator','coordinator']));

create policy "staff read enrollments" on public.sifa_enrollments
for select to authenticated using (public.sifa_has_staff_role(array['administrator','coordinator','finance_reviewer']));

create policy "student view own invoices" on public.sifa_fee_invoices
for select to authenticated using (
  exists (select 1 from public.sifa_enrollments e where e.id = enrollment_id and e.student_user_id = auth.uid())
  or public.sifa_has_staff_role(array['administrator','finance_reviewer','coordinator'])
);
create policy "finance staff read invoices" on public.sifa_fee_invoices
for select to authenticated using (public.sifa_has_staff_role(array['administrator','finance_reviewer','coordinator']));

create policy "student view own receipts" on public.sifa_payment_receipts
for select to authenticated using (student_user_id = auth.uid() or public.sifa_has_staff_role(array['administrator','finance_reviewer']));
create policy "finance staff read receipts" on public.sifa_payment_receipts
for select to authenticated using (public.sifa_has_staff_role(array['administrator','finance_reviewer']));

create policy "staff read certificate registry" on public.sifa_certificate_registry
for select to authenticated using (public.sifa_has_staff_role(array['administrator','coordinator']));

-- No browser-facing INSERT/UPDATE/DELETE grants or policies are created for
-- workflow tables. Mutations go through server-side Edge Functions that check
-- the caller role, validate business rules, and append audit entries.


alter table public.sifa_fee_invoices add column if not exists invoice_type text not null default 'monthly_course';
alter table public.sifa_fee_invoices drop constraint if exists sifa_fee_invoices_invoice_type_check;
alter table public.sifa_fee_invoices add constraint sifa_fee_invoices_invoice_type_check check (invoice_type in ('monthly_course','certificate_fee'));
alter table public.sifa_fee_invoices drop constraint if exists sifa_fee_invoices_enrollment_id_period_start_key;
create unique index if not exists sifa_fee_invoice_period_type_unique on public.sifa_fee_invoices(enrollment_id,period_start,invoice_type);

create unique index if not exists sifa_enrollment_public_app_unique on public.sifa_enrollments(public_application_id) where public_application_id is not null;
create unique index if not exists sifa_enrollment_legacy_app_unique on public.sifa_enrollments(application_id) where application_id is not null;

-- Private bucket used by server-side upload functions only. No anon/authenticated
-- storage policies are created; browser clients must never receive service credentials.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('sifa-private-documents', 'sifa-private-documents', false, 5242880,
        array['application/pdf','image/jpeg','image/png','application/msword','application/vnd.openxmlformats-officedocument.wordprocessingml.document'])
on conflict (id) do update set public = false, file_size_limit = 5242880,
  allowed_mime_types = excluded.allowed_mime_types;

-- Public certificate verification exposes only the minimum information needed
-- to verify authenticity. It never exposes internal student IDs or documents.
create or replace function public.sifa_verify_certificate(p_code text)
returns table (certificate_code text, student_display_name text, program text, issued_on date, status text, verified boolean)
language sql stable security definer
set search_path = ''
as $$
  select c.certificate_code, c.student_display_name, c.program, c.issued_on, c.status,
         (c.status = 'active') as verified
  from public.sifa_certificate_registry c
  where upper(c.certificate_code) = upper(trim(p_code))
  limit 1;
$$;
revoke all on function public.sifa_verify_certificate(text) from public;
grant execute on function public.sifa_verify_certificate(text) to anon, authenticated;

-- Keep timestamps current on staff decisions and administrative updates.
create or replace function public.sifa_set_updated_at()
returns trigger language plpgsql set search_path = '' as $$
begin new.updated_at = now(); return new; end; $$;
drop trigger if exists sifa_public_apps_updated_at on public.sifa_public_applications;
create trigger sifa_public_apps_updated_at before update on public.sifa_public_applications
for each row execute function public.sifa_set_updated_at();
drop trigger if exists sifa_enrollments_updated_at on public.sifa_enrollments;
create trigger sifa_enrollments_updated_at before update on public.sifa_enrollments
for each row execute function public.sifa_set_updated_at();

commit;
