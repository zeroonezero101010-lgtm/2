-- Выполнить в Supabase → SQL Editor после создания проекта.
create extension if not exists pgcrypto;
create table if not exists public.admins (user_id uuid primary key references auth.users(id) on delete cascade);
create table if not exists public.projects (id uuid primary key default gen_random_uuid(), title text not null, sort_order integer not null default 0, created_at timestamptz not null default now());
create table if not exists public.project_images (id uuid primary key default gen_random_uuid(), project_id uuid not null references public.projects(id) on delete cascade, storage_path text not null, sort_order integer not null default 0, created_at timestamptz not null default now());
alter table public.admins enable row level security;
alter table public.projects enable row level security;
alter table public.project_images enable row level security;
create or replace function public.is_portfolio_admin() returns boolean language sql stable security definer set search_path = public as $$ select exists(select 1 from public.admins where user_id = auth.uid()); $$;
grant execute on function public.is_portfolio_admin() to anon, authenticated;
grant select on public.projects, public.project_images to anon, authenticated;
grant insert, update, delete on public.projects, public.project_images to authenticated;
create policy "public read projects" on public.projects for select using (true);
create policy "admin insert projects" on public.projects for insert to authenticated with check (public.is_portfolio_admin());
create policy "admin update projects" on public.projects for update to authenticated using (public.is_portfolio_admin()) with check (public.is_portfolio_admin());
create policy "admin delete projects" on public.projects for delete to authenticated using (public.is_portfolio_admin());
create policy "public read project images" on public.project_images for select using (true);
create policy "admin insert project images" on public.project_images for insert to authenticated with check (public.is_portfolio_admin());
create policy "admin update project images" on public.project_images for update to authenticated using (public.is_portfolio_admin()) with check (public.is_portfolio_admin());
create policy "admin delete project images" on public.project_images for delete to authenticated using (public.is_portfolio_admin());
insert into storage.buckets (id,name,public) values ('portfolio-images','portfolio-images',true) on conflict (id) do update set public = true;
create policy "public can view portfolio images" on storage.objects for select using (bucket_id = 'portfolio-images');
create policy "admins upload portfolio images" on storage.objects for insert to authenticated with check (bucket_id = 'portfolio-images' and public.is_portfolio_admin());
create policy "admins update portfolio images" on storage.objects for update to authenticated using (bucket_id = 'portfolio-images' and public.is_portfolio_admin()) with check (bucket_id = 'portfolio-images' and public.is_portfolio_admin());
create policy "admins delete portfolio images" on storage.objects for delete to authenticated using (bucket_id = 'portfolio-images' and public.is_portfolio_admin());
-- После создания пользователя через Authentication → Users вставьте его UUID:
-- insert into public.admins(user_id) values ('UUID_ВАШЕГО_ПОЛЬЗОВАТЕЛЯ');
