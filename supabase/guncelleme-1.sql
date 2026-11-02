-- Güncelleme 1: müşteri sepette ilgilenen personeli seçebilir
-- Supabase > SQL Editor > New query: bu dosyanın tamamını yapıştırıp Run'a basın.

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
    -- Ekip üyesi kendi adına; müşteri seçtiği personel adına (geçerli bir ekip üyesiyse) teklif açar
    new.staff_id := coalesce(my_team_id(), (select t.id from team t where t.id = new.staff_id));
  end if;
  return new;
end $$;


-- Müşterinin sepette seçebilmesi için ekip adları (yalnızca ad ve rol)
create or replace function public.team_names() returns table (id uuid, name text, role text)
language sql stable security definer set search_path = public as $$
  select id, name, role from team order by role desc, name;
$$;

grant execute on function public.coupon_check(text), public.team_first_login(text, text), public.team_names() to anon, authenticated;
