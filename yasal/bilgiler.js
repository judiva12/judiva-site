// Yasal metinlerdeki şirket bilgileri. Boş bırakılan alan sayfada sarı "doldurulacak" etiketiyle görünür.
// Bilgiyi bir kere buraya yazmanız yeterli; tüm yasal sayfalar buradan okur.
window.JUDIVA_YASAL = {
  unvan: '',          // Ticaret sicilindeki tam unvan, ör. "Judiva Gıda San. ve Tic. Ltd. Şti."
  adres: '',          // Merkez adresi
  mersis: '',         // MERSİS numarası
  vergi: '',          // Vergi dairesi ve vergi numarası
  telefon: '',        // Müşteri hattı
  eposta: '',         // KVKK başvurularının geleceği e-posta, ör. kvkk@judiva.com.tr
  kep: '',            // KEP adresi (varsa)
  sunucu: '',         // Supabase projesinin bölgesi, ör. "Almanya (Frankfurt, AB)"
  mahkeme: '',        // Yetkili mahkeme ve icra daireleri için il, ör. "İstanbul (Anadolu)"
  guncelleme: '20 Kasım 2026' // Metinlerin son güncellenme tarihi
};
(function () {
  const d = window.JUDIVA_YASAL;
  document.querySelectorAll('[data-k]').forEach(el => {
    const v = d[el.dataset.k];
    if (v) { el.textContent = v; el.classList.remove('ph'); } else el.classList.add('ph');
  });
})();
