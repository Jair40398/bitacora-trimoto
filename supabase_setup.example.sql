-- BITÁCORA TRIMOTO TC2-160 · Pegar completo en Supabase > SQL Editor > Run
-- ANTES DE EJECUTAR: cambia CAMBIA-ESTA-CLAVE (cerca del final) por tu clave de escritura (8 o más caracteres).
-- Esta versión de ejemplo NO contiene ninguna clave real; no pongas tu clave real en un repositorio público.

create extension if not exists pgcrypto with schema extensions;

create table if not exists public.partes(
  id uuid primary key default gen_random_uuid(), created_at timestamptz default now(),
  op text, fe date, hs time, hr time, bs int, br int, kg int, dst text,
  c1 boolean default true, c2 boolean default true, c3 boolean default true, c4 boolean default false, ob text);
create table if not exists public.fallas(
  id uuid primary key default gen_random_uuid(), created_at timestamptz default now(),
  sis text, des text, op text, fe date, est text default 'pendiente');
create table if not exists public.mant(
  id uuid primary key default gen_random_uuid(), created_at timestamptz default now(),
  tipo text, fe date, op text, psid numeric, psit numeric);
create table if not exists public.acceso(id int primary key default 1 check (id=1), clave_hash text not null);

-- Seguridad: todos leen partes, fallas y mant; nadie escribe directo; "acceso" es invisible
alter table public.partes enable row level security;
alter table public.fallas enable row level security;
alter table public.mant enable row level security;
alter table public.acceso enable row level security;
drop policy if exists leer on public.partes; create policy leer on public.partes for select to anon using (true);
drop policy if exists leer on public.fallas; create policy leer on public.fallas for select to anon using (true);
drop policy if exists leer on public.mant;   create policy leer on public.mant   for select to anon using (true);
revoke all on public.acceso from anon, authenticated;
revoke insert, update, delete on public.partes, public.fallas, public.mant from anon, authenticated;

-- Verificación de la clave (espera 1.5 s si es incorrecta para frenar intentos masivos)
create or replace function public._ok(p_clave text) returns boolean
language plpgsql security definer set search_path = public, extensions as $$
begin
  if exists(select 1 from acceso where clave_hash = crypt(coalesce(p_clave,''), clave_hash)) then return true; end if;
  perform pg_sleep(1.5); return false;
end $$;
revoke execute on function public._ok(text) from public, anon, authenticated;

create or replace function public.guardar_parte(p_clave text, p jsonb) returns void
language plpgsql security definer set search_path = public, extensions as $$
begin
  if not _ok(p_clave) then raise exception 'clave incorrecta'; end if;
  insert into partes(op,fe,hs,hr,bs,br,kg,dst,c1,c2,c3,c4,ob) values(
    left(p->>'op',80), (p->>'fe')::date, nullif(p->>'hs','')::time, nullif(p->>'hr','')::time,
    nullif(p->>'bs','')::int, nullif(p->>'br','')::int, nullif(p->>'kg','')::int, left(p->>'dst',200),
    coalesce((p->>'c1')::boolean,true), coalesce((p->>'c2')::boolean,true), coalesce((p->>'c3')::boolean,true),
    coalesce((p->>'c4')::boolean,false), left(p->>'ob',1000));
end $$;

create or replace function public.guardar_falla(p_clave text, p jsonb) returns void
language plpgsql security definer set search_path = public, extensions as $$
begin
  if not _ok(p_clave) then raise exception 'clave incorrecta'; end if;
  insert into fallas(sis,des,op,fe) values(left(p->>'sis',10), left(p->>'des',1000), left(p->>'op',80), (p->>'fe')::date);
end $$;

create or replace function public.guardar_mant(p_clave text, p jsonb) returns void
language plpgsql security definer set search_path = public, extensions as $$
begin
  if not _ok(p_clave) then raise exception 'clave incorrecta'; end if;
  if (p->>'tipo') not in ('llantas','carga') then raise exception 'tipo invalido'; end if;
  insert into mant(tipo,fe,op,psid,psit) values(p->>'tipo', (p->>'fe')::date, left(p->>'op',80),
    nullif(p->>'psid','')::numeric, nullif(p->>'psit','')::numeric);
end $$;

create or replace function public.resolver_falla(p_clave text, p_id uuid) returns void
language plpgsql security definer set search_path = public, extensions as $$
begin
  if not _ok(p_clave) then raise exception 'clave incorrecta'; end if;
  update fallas set est='resuelta' where id=p_id;
end $$;

create or replace function public.borrar_registro(p_clave text, p_tabla text, p_id uuid) returns void
language plpgsql security definer set search_path = public, extensions as $$
begin
  if not _ok(p_clave) then raise exception 'clave incorrecta'; end if;
  if p_tabla not in ('partes','fallas','mant') then raise exception 'tabla invalida'; end if;
  execute format('delete from public.%I where id=$1', p_tabla) using p_id;
end $$;

-- Permisos para la clave pública (anon): leer las tablas y llamar a las funciones
grant usage on schema public to anon;
grant select on public.partes, public.fallas, public.mant to anon;
grant execute on function
  public.guardar_parte(text, jsonb), public.guardar_falla(text, jsonb), public.guardar_mant(text, jsonb),
  public.resolver_falla(text, uuid), public.borrar_registro(text, text, uuid)
to anon;

-- Clave de escritura (CÁMBIALA; usa 8 o más caracteres)
insert into public.acceso(id, clave_hash) values (1, extensions.crypt('CAMBIA-ESTA-CLAVE', extensions.gen_salt('bf')))
on conflict (id) do update set clave_hash = excluded.clave_hash;
-- Para cambiarla después, vuelve a correr SOLO este último bloque con la clave nueva.
