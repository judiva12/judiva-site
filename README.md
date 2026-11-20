# Judiva

Judiva menü ve teklif sitesi. Mezeler, pastalar, börekler ve içecekler; sepet, kupon, PDF teklif, müşteri üyeliği, personel ve müdür paneli.

Site tek bir `index.html` dosyasıdır. Ürün görselleri `imgs/`, katmanlı pasta kareleri `cake/` klasöründedir.
Bu depoya yapılan her değişiklik GitHub Pages üzerinden birkaç dakika içinde yayına çıkar.

## Yasal metinler

KVKK aydınlatma metni, gizlilik ve çerez politikası, kullanım koşulları ve KVKK başvuru formu `yasal/` klasöründedir (judiva.com.tr/yasal/).
Şirket unvanı, adres, MERSİS, e-posta gibi bilgiler yalnızca `yasal/bilgiler.js` dosyasından doldurulur; boş alanlar sayfada sarı etiketle görünür.
Metinler değişirse `bilgiler.js` içindeki `guncelleme` tarihini ve `index.html` içindeki `LEGAL_VER` değerini güncelleyin.
