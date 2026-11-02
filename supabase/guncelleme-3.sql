-- Judiva güncelleme 3: Onur ismi ve sepetteki personel listesi
-- Supabase > SQL Editor'e yapıştırıp Run deyin.

alter table public.team add column if not exists in_picker boolean not null default true;

-- "Müdür 2" kaydı Onur oluyor ve müşterinin personel listesinde görünmüyor.
-- Henüz ilk girişini yapmadıysa kullanıcı adı da "onur" olur.
update public.team set name = 'Onur', in_picker = false where username in ('mudur2', 'onur');
update public.team set username = 'onur' where username = 'mudur2' and auth_id is null;

create or replace function public.team_names() returns table (id uuid, name text, role text)
language sql stable security definer set search_path = public as $$
  select id, name, role from team where in_picker order by name;
$$;
