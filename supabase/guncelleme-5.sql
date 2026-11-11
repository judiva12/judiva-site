-- Judiva güncelleme 5: ürün fotoğrafları için depo
-- Supabase > SQL Editor'e yapıştırıp Run deyin.

-- Herkesin görebildiği "urunler" fotoğraf deposu (en fazla 5 MB, sadece resim)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('urunler', 'urunler', true, 5242880, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update set public = true;

-- Fotoğrafları sadece müdür yükler, değiştirir ve siler
drop policy if exists "urunler_yukle" on storage.objects;
create policy "urunler_yukle" on storage.objects for insert to authenticated
  with check (bucket_id = 'urunler' and public.is_mgr());
drop policy if exists "urunler_guncelle" on storage.objects;
create policy "urunler_guncelle" on storage.objects for update to authenticated
  using (bucket_id = 'urunler' and public.is_mgr());
drop policy if exists "urunler_sil" on storage.objects;
create policy "urunler_sil" on storage.objects for delete to authenticated
  using (bucket_id = 'urunler' and public.is_mgr());
