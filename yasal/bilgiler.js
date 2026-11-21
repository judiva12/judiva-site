// Yasal metinlerdeki şirket bilgileri. Boş bırakılan alan sayfada sarı "doldurulacak" etiketiyle görünür.
// Bilgiyi bir kere buraya yazmanız yeterli; tüm yasal sayfalar buradan okur.
window.JUDIVA_YASAL = {
  unvan: 'Veron Bilişim ve Yazılım Hizmetleri Limited Şirketi', // Ticaret sicilindeki tam unvan
  adres: 'İçerenköy Mah. Şafak Cami Sk. Bulut Apt. No: 34 İç Kapı No: 10, 34752 Ataşehir / İstanbul, Türkiye', // Merkez adresi
  sube: 'Oruçreis Mah., Giyimkent Sitesi Ticaret Cad. No: 10A-12A, B114, 34205 Esenler / İstanbul, Türkiye', // Şube adresi
  mersis: '0925131681300001',         // MERSİS numarası
  vergi: 'Kozyatağı Vergi Dairesi, VKN 9251316813',          // Vergi dairesi ve vergi numarası
  kep: 'veronbilisim@hs06.kep.tr',            // KEP adresi (varsa)
  guncelleme: '21 Kasım 2026' // Metinlerin son güncellenme tarihi
};
(function () {
  const d = window.JUDIVA_YASAL;
  document.querySelectorAll('[data-k]').forEach(el => {
    const v = d[el.dataset.k];
    if (v) { el.textContent = v; el.classList.remove('ph'); } else el.classList.add('ph');
  });
})();
