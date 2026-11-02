-- Judiva güncelleme 2: müşteri şifre sıfırlama
-- Supabase > SQL Editor'e yapıştırıp Run deyin.

create or replace function public.customers_guard() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'UPDATE' then
    if not (old.auth_id is null and new.auth_id = auth.uid() and current_setting('judiva.claim', true) = 'on')
       and not (new.auth_id is null and current_setting('judiva.reset', true) = 'on') then
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
    if not (old.auth_id is null and current_setting('judiva.claim', true) = 'on')
       and not (new.auth_id is null and current_setting('judiva.reset', true) = 'on') then
      new.auth_id := old.auth_id;
    end if;
    new.staff_id := old.staff_id;
  else
    new.auth_id := (select auth_id from customers where id = new.data->>'customerId');
    -- Ekip üyesi kendi adına; müşteri seçtiği personel adına (geçerli bir ekip üyesiyse) teklif açar
    new.staff_id := coalesce(my_team_id(), (select t.id from team t where t.id = new.staff_id));
  end if;
  return new;
end $$;

create or replace function public.customer_reset(p_id text) returns void
language plpgsql security definer set search_path = public as $$
declare v_auth uuid;
begin
  if not is_team() then raise exception 'Yalnızca ekip'; end if;
  select auth_id into v_auth from customers where id = p_id;
  if v_auth is null then raise exception 'Bu müşterinin üyeliği yok'; end if;
  perform set_config('judiva.reset', 'on', true);
  update customers set auth_id = null where id = p_id;
  update offers set auth_id = null where auth_id = v_auth;
  perform set_config('judiva.reset', 'off', true);
  delete from auth.users where id = v_auth;
end $$;

grant execute on function public.customer_reset(text) to authenticated;
