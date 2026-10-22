-- SIFA Student Classroom — learning materials storage and metadata
-- Review and run only after approving backend deployment.
create table if not exists public.sifa_learning_materials (
 id uuid primary key default gen_random_uuid(),
 program text not null,
 material_type text not null default 'book' check (material_type in ('book','lesson','assignment','announcement')),
 title text not null check (length(trim(title)) between 2 and 180),
 description text not null default '',
 original_filename text not null,
 storage_path text not null unique,
 content_type text not null default 'application/pdf',
 byte_size bigint not null check (byte_size > 0 and byte_size <= 20971520),
 published boolean not null default false,
 sort_order integer not null default 0,
 created_by uuid not null references auth.users(id),
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create index if not exists sifa_learning_materials_program_published_idx on public.sifa_learning_materials(program,published,sort_order,created_at desc);
alter table public.sifa_learning_materials enable row level security;
revoke all on public.sifa_learning_materials from anon, authenticated;
grant select, insert, update, delete on public.sifa_learning_materials to service_role;
insert into storage.buckets (id,name,public,file_size_limit,allowed_mime_types)
values ('sifa-learning-materials','sifa-learning-materials',false,20971520,array['application/pdf'])
on conflict (id) do update set public=false,file_size_limit=20971520,allowed_mime_types=array['application/pdf'];
-- No browser storage policies for this bucket: all access is mediated by sifa-classroom-api.
