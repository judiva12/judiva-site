-- Judiva güncelleme 4: personel kendi tekliflerini silebilsin (müdür hepsini)
-- Supabase > SQL Editor'e yapıştırıp Run deyin.

drop policy if exists offers_delete on public.offers;
create policy offers_delete on public.offers for delete using (is_mgr() or staff_id = my_team_id());
