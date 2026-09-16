-- =============================================================================
-- Clover — VERİ göçü: 'Ürünler' menüsü tek kaynağa iniyor (16.09.2026)
--
-- NE DEĞİŞTİ: Üst menüdeki 'Ürünler' açılır listesinin İKİ kaynağı vardı —
-- Menü Linkleri'ndeki `section = 'header-products'` kayıtları VE Sayfalar'daki
-- `showInProductsMenu` kutusu. Site ikisini birleştiriyor ama adrese göre
-- tekilleştirmiyordu: aynı sayfayı her iki yoldan da ekleyen bir editör menüde
-- AYNI sayfayı iki kez görüyordu (kullanıcı tarafından canlıda yaşandı).
-- Çözüm olarak tekilleştirme eklemek yerine ikinci kaynak kaldırıldı — artık
-- tek yol Sayfalar'daki kutu, yani çakışma yapısal olarak imkânsız.
--
-- BU SCRIPT NEDEN GEREKLİ: `header-products` seçeneği CMS'ten kalktığı için,
-- o bölümde duran mevcut kayıtlar artık HİÇBİR YERDE render edilmiyor. Bu
-- script çalıştırılmazsa o linkler menüden sessizce kaybolur. Script her
-- `header-products` satırını, işaret ettiği Sayfa kaydının kendi kutusuna
-- taşıyor (etiket ve sıra korunarak) ve ardından artık ölü olan satırı siliyor.
--
-- ŞEMA DEĞİŞİKLİĞİ YOK — bu tamamen bir VERİ göçü. `enum_nav_links_section`
-- tipindeki `header-products` değeri bilinçli olarak DÜŞÜRÜLMEDİ: Postgres
-- enum değeri silmeyi desteklemiyor (tipin tamamını yeniden yaratmak gerekir)
-- ve kullanılmayan bir değer zararsız.
--
-- NASIL UYGULANIR (DBeaver): hedef veritabanına bağlan, SQL Editor'de bu
-- dosyayı aç, "Execute script" (Alt+X) ile TAMAMINI çalıştır. Tek transaction
-- (BEGIN/COMMIT) — bir satır bile hata verirse hiçbir şey uygulanmaz.
--
-- TEKRAR ÇALIŞTIRILABİLİR (idempotent): ikinci çalıştırmada taşınacak
-- `header-products` satırı kalmadığı için hiçbir şey yapmaz.
-- =============================================================================

BEGIN;

-- -----------------------------------------------------------------------
-- 1. Yayındaki (live) tablo: her header-products linkini, href'inin işaret
--    ettiği sayfanın kendi 'Ürünler menüsünde göster' kutusuna taşı.
--
--    Eşleşme href üzerinden: '/vodafone-pay-kart' → slug 'vodafone-pay-kart'.
--    Sadece BAŞINDA '/' olan iç adresler eşleşir; dış bağlantılar (https://...)
--    ve Sayfa karşılığı olmayan elle yazılmış rotalar eşleşmez — onlar
--    aşağıdaki 3. adımda raporlanır ve SİLİNMEZ.
-- -----------------------------------------------------------------------

UPDATE pages p
SET    show_in_products_menu = true,
       products_menu_label   = COALESCE(NULLIF(p.products_menu_label, ''), n.label),
       products_menu_order   = COALESCE(p.products_menu_order, n.order)
FROM   nav_links n
WHERE  n.section = 'header-products'
  AND  p.slug = substring(n.href from 2)
  AND  n.href LIKE '/%';

-- Aynısını sürüm (taslak geçmişi) tablosunda da yap — Payload admin'i
-- drafts-enabled bir koleksiyonun düzenleme ekranını sürüm tablosundan
-- okuyor; burayı atlamak, editörün panelde kutuyu işaretsiz görmesine yol
-- açardı (29e'deki "boş _v tabloları" hatasının aynısı).
UPDATE _pages_v v
SET    version_show_in_products_menu = true,
       version_products_menu_label   = COALESCE(NULLIF(v.version_products_menu_label, ''), n.label),
       version_products_menu_order   = COALESCE(v.version_products_menu_order, n.order)
FROM   nav_links n
WHERE  n.section = 'header-products'
  AND  v.version_slug = substring(n.href from 2)
  AND  n.href LIKE '/%';

-- -----------------------------------------------------------------------
-- 2. Taşınmış olan (yani bir Sayfa karşılığı bulunan) header-products
--    satırlarını sil. Sürüm tablosundaki karşılıkları da gitsin.
-- -----------------------------------------------------------------------

DELETE FROM _nav_links_v v
USING  nav_links n, pages p
WHERE  v.parent_id = n.id
  AND  n.section = 'header-products'
  AND  n.href LIKE '/%'
  AND  p.slug = substring(n.href from 2);

DELETE FROM nav_links n
USING  pages p
WHERE  n.section = 'header-products'
  AND  n.href LIKE '/%'
  AND  p.slug = substring(n.href from 2);

-- -----------------------------------------------------------------------
-- 3. Taşınamayan satırlar (dış bağlantı ya da Sayfa karşılığı olmayan rota).
--    Bunlar BİLİNÇLİ olarak silinmiyor — artık hiçbir yerde render
--    edilmiyorlar ama veri kaybı yaşatmadan görülebilsinler diye duruyorlar.
--    Aşağıdaki sorgu kalan varsa listeler; çıktı boşsa her şey taşındı.
-- -----------------------------------------------------------------------

SELECT n.id, n.label, n.href, n."order", n._status,
       'TASINAMADI — Sayfa karsiligi yok; bu link artik menude gorunmuyor' AS not
FROM   nav_links n
WHERE  n.section = 'header-products';

COMMIT;
