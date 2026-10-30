-- Judiva veritabanı kurulumu
-- Supabase panelinde SQL Editor > New query: bu dosyanın tamamını yapıştırıp Run'a basın.
-- Tekrar çalıştırmak güvenlidir: var olan tablo ve kayıtlar silinmez.

-- Ekip girişi:   kullanıcıadı@ekip.judiva.com.tr  (Supabase Auth, e-posta + şifre)
-- Müşteri girişi: 5321112233@uye.judiva.com.tr    (telefonun son 10 hanesi)
-- Bu adreslere e-posta gönderilmez; Authentication > Providers > Email > "Confirm email" KAPALI olmalı.

create extension if not exists pgcrypto;

-- ---------- Tablolar ----------
-- Site kayıtları JSON olarak tutulur (data); erişim kuralları için gereken alanlar ayrı sütunlarda.

create table if not exists public.team (
  id uuid primary key default gen_random_uuid(),
  username text not null unique,
  name text not null,
  role text not null check (role in ('personel', 'mudur')),
  auth_id uuid unique references auth.users (id) on delete set null,
  temp_pw text,                      -- ilk giriş şifresi; ilk girişte kişi kendi şifresini belirler ve bu silinir
  created_at timestamptz not null default now()
);

create table if not exists public.customers (
  id text primary key,
  data jsonb not null default '{}',
  auth_id uuid unique references auth.users (id) on delete set null,  -- siteden üye olduysa
  created_at timestamptz not null default now()
);

create table if not exists public.offers (
  id text primary key,
  data jsonb not null default '{}',
  auth_id uuid references auth.users (id) on delete set null,     -- teklifin müşterisi üye ise
  staff_id uuid references public.team (id) on delete set null,  -- teklifi hazırlayan ekip üyesi
  created_at timestamptz not null default now()
);

create table if not exists public.coupons (
  id text primary key,
  data jsonb not null default '{}',
  created_at timestamptz not null default now()
);

create table if not exists public.products (
  id text primary key,
  data jsonb not null default '{}',
  created_at timestamptz not null default now()
);

create table if not exists public.settings (
  id text primary key,
  data jsonb not null default '{}'
);

-- ---------- Yardımcılar ----------
create or replace function public.is_team() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from team where auth_id = auth.uid());
$$;

create or replace function public.is_mgr() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from team where auth_id = auth.uid() and role = 'mudur');
$$;

create or replace function public.my_team_id() returns uuid
language sql stable security definer set search_path = public as $$
  select id from team where auth_id = auth.uid();
$$;

create or replace function public.phone_key(p text) returns text
language sql immutable as $$
  select right(regexp_replace(coalesce(p, ''), '\D', '', 'g'), 10);
$$;

-- Üyelik ve hazırlayan bilgisi sunucuda yazılır; tarayıcıdan gelen değer dikkate alınmaz
create or replace function public.customers_guard() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'UPDATE' then
    if not (old.auth_id is null and new.auth_id = auth.uid() and current_setting('judiva.claim', true) = 'on') then
      new.auth_id := old.auth_id;
    end if;
  elsif is_team() then
    new.auth_id := null;
  else
    new.auth_id := auth.uid();
  end if;
  return new;
end $$;

create or replace function public.offers_guard() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'UPDATE' then
    if not (old.auth_id is null and current_setting('judiva.claim', true) = 'on') then
      new.auth_id := old.auth_id;
    end if;
    new.staff_id := old.staff_id;
  else
    new.auth_id := (select auth_id from customers where id = new.data->>'customerId');
    new.staff_id := my_team_id();
  end if;
  return new;
end $$;

drop trigger if exists customers_guard on public.customers;
create trigger customers_guard before insert or update on public.customers
  for each row execute function public.customers_guard();
drop trigger if exists offers_guard on public.offers;
create trigger offers_guard before insert or update on public.offers
  for each row execute function public.offers_guard();

-- ---------- Erişim kuralları ----------
alter table public.team enable row level security;
alter table public.customers enable row level security;
alter table public.offers enable row level security;
alter table public.coupons enable row level security;
alter table public.products enable row level security;
alter table public.settings enable row level security;

drop policy if exists team_read on public.team;
create policy team_read on public.team for select using (is_team());
drop policy if exists team_write on public.team;
create policy team_write on public.team for all using (is_mgr()) with check (is_mgr());

drop policy if exists customers_read on public.customers;
create policy customers_read on public.customers for select using (is_team() or auth_id = auth.uid());
drop policy if exists customers_insert on public.customers;
create policy customers_insert on public.customers for insert with check (is_team() or auth_id = auth.uid());
drop policy if exists customers_update on public.customers;
create policy customers_update on public.customers for update using (is_team() or auth_id = auth.uid()) with check (is_team() or auth_id = auth.uid());
drop policy if exists customers_delete on public.customers;
create policy customers_delete on public.customers for delete using (is_mgr());

-- Müdür tüm teklifleri, personel kendi hazırladıklarını, üye müşteri kendisine yapılanları görür
drop policy if exists offers_read on public.offers;
create policy offers_read on public.offers for select using (is_mgr() or staff_id = my_team_id() or auth_id = auth.uid());
drop policy if exists offers_insert on public.offers;
create policy offers_insert on public.offers for insert with check (is_team() or (auth_id is not null and auth_id = auth.uid()));
drop policy if exists offers_update on public.offers;
create policy offers_update on public.offers for update using (is_mgr() or staff_id = my_team_id()) with check (is_team());
drop policy if exists offers_delete on public.offers;
create policy offers_delete on public.offers for delete using (is_mgr());

-- Kuponları ekip görür; müşteri sadece yazdığı kodu coupon_check ile sorgular
drop policy if exists coupons_read on public.coupons;
create policy coupons_read on public.coupons for select using (is_team());
drop policy if exists coupons_write on public.coupons;
create policy coupons_write on public.coupons for all using (is_mgr()) with check (is_mgr());

drop policy if exists products_read on public.products;
create policy products_read on public.products for select using (true);
drop policy if exists products_write on public.products;
create policy products_write on public.products for all using (is_mgr()) with check (is_mgr());

drop policy if exists settings_read on public.settings;
create policy settings_read on public.settings for select using (true);
drop policy if exists settings_write on public.settings;
create policy settings_write on public.settings for all using (is_mgr()) with check (is_mgr());

-- ---------- Sitenin çağırdığı işlemler ----------

-- Kupon kodunu sorgula (aktif kupon varsa bilgisini döndürür)
create or replace function public.coupon_check(p_code text) returns jsonb
language sql stable security definer set search_path = public as $$
  select data || jsonb_build_object('id', id) from coupons
  where upper(data->>'code') = upper(trim(p_code)) and coalesce((data->>'active')::boolean, true)
  limit 1;
$$;

-- Ekip girişi: kullanıcı adı ilk girişini bekliyor mu ve verilen geçici şifre doğru mu
create or replace function public.team_first_login(p_username text, p_pw text) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from team where username = lower(trim(p_username)) and auth_id is null and temp_pw = p_pw);
$$;

-- İlk girişte yeni açılan hesabı ekip kaydına bağla
create or replace function public.team_claim(p_username text, p_pw text) returns uuid
language plpgsql security definer set search_path = public as $$
declare v_id uuid;
begin
  if auth.uid() is null or (select email from auth.users where id = auth.uid()) <> lower(trim(p_username)) || '@ekip.judiva.com.tr' then
    raise exception 'Hesap bu kullanıcı adına ait değil';
  end if;
  update team set auth_id = auth.uid(), temp_pw = null
    where username = lower(trim(p_username)) and auth_id is null and temp_pw = p_pw
    returning id into v_id;
  if v_id is null then raise exception 'Geçici şifre yanlış'; end if;
  return v_id;
end $$;

-- Müdür: bir ekip üyesinin şifresini sıfırla (kişi yeni geçici şifreyle tekrar ilk girişini yapar)
create or replace function public.team_reset(p_id uuid, p_temp text) returns void
language plpgsql security definer set search_path = public as $$
declare v_auth uuid;
begin
  if not is_mgr() then raise exception 'Yalnızca müdür'; end if;
  if length(coalesce(p_temp, '')) < 4 then raise exception 'Geçici şifre en az 4 karakter olmalı'; end if;
  select auth_id into v_auth from team where id = p_id;
  update team set auth_id = null, temp_pw = p_temp where id = p_id;
  if v_auth is not null then delete from auth.users where id = v_auth; end if;
end $$;

-- Müdür: ekip üyesini kaldır (giriş hesabı da silinir)
create or replace function public.team_remove(p_id uuid) returns void
language plpgsql security definer set search_path = public as $$
declare v_auth uuid;
begin
  if not is_mgr() then raise exception 'Yalnızca müdür'; end if;
  if (select auth_id from team where id = p_id) = auth.uid() then raise exception 'Kendinizi kaldıramazsınız'; end if;
  if (select role from team where id = p_id) = 'mudur' and (select count(*) from team where role = 'mudur') <= 1 then
    raise exception 'En az bir müdür kalmalı';
  end if;
  select auth_id into v_auth from team where id = p_id;
  delete from team where id = p_id;
  if v_auth is not null then delete from auth.users where id = v_auth; end if;
end $$;

-- Yeni üye müşteri: aynı telefonla daha önce açılmış (üye olmayan) müşteri kaydı varsa onu üyeye bağla
create or replace function public.customer_claim(p_phone text) returns text
language plpgsql security definer set search_path = public as $$
declare v_id text;
begin
  if auth.uid() is null or (select email from auth.users where id = auth.uid()) <> phone_key(p_phone) || '@uye.judiva.com.tr' then
    raise exception 'Hesap bu telefona ait değil';
  end if;
  select id into v_id from customers where auth_id = auth.uid();
  if v_id is not null then return v_id; end if;
  perform set_config('judiva.claim', 'on', true);
  update customers set auth_id = auth.uid()
    where id = (select id from customers where auth_id is null and phone_key(data->>'phone') = phone_key(p_phone) order by created_at limit 1)
    returning id into v_id;
  if v_id is not null then
    update offers set auth_id = auth.uid() where data->>'customerId' = v_id;
  end if;
  perform set_config('judiva.claim', 'off', true);
  return v_id;
end $$;

grant execute on function public.coupon_check(text), public.team_first_login(text, text) to anon, authenticated;
grant execute on function public.team_claim(text, text), public.team_reset(uuid, text), public.team_remove(uuid), public.customer_claim(text) to authenticated;
grant select on public.products, public.settings to anon;
grant select, insert, update, delete on public.team, public.customers, public.offers, public.coupons, public.products, public.settings to authenticated;

-- ---------- Canlı güncelleme ----------
do $$ begin
  begin alter publication supabase_realtime add table public.offers; exception when others then null; end;
  begin alter publication supabase_realtime add table public.customers; exception when others then null; end;
  begin alter publication supabase_realtime add table public.coupons; exception when others then null; end;
  begin alter publication supabase_realtime add table public.products; exception when others then null; end;
  begin alter publication supabase_realtime add table public.settings; exception when others then null; end;
  begin alter publication supabase_realtime add table public.team; exception when others then null; end;
end $$;

-- ---------- Başlangıç kayıtları ----------
insert into public.settings (id, data) values ('main', '{"validDays": 15}') on conflict (id) do nothing;

-- Geçici şifre 1111: her kişi ilk girişte kendi şifresini (en az 6 karakter) belirler
insert into public.team (username, name, role, temp_pw) values
  ('azra', 'Azra', 'mudur', '1111'),
  ('mudur2', 'Müdür 2', 'mudur', '1111'),
  ('ebrar', 'Ebrar', 'personel', '1111'),
  ('miray', 'Miray', 'personel', '1111')
on conflict (username) do nothing;

insert into public.coupons (id, data) values
  ('k_ornek10', '{"code": "ORNEK10", "type": "yuzde", "value": 10, "min": 0, "expires": null, "note": "Örnek kupon", "active": true}')
on conflict (id) do nothing;
