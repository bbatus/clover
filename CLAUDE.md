@AGENTS.md

## İleride yapılacaklar (backlog — 17.09.2026, henüz başlanmadı)

Kullanıcıyla konuşuldu, "daha sonranın konusu ama aklımızda tutalım". Biri istemeden başlama; başlarken önce kullanıcıyla kapsamı netleştir.

- **Zamanlanmış yayın (schedule publish):** Bir kampanya (sonra genel olarak her içerik) ileri bir tarihte, ör. ayın 1'inde 00:00'da, kendiliğinden yayına girebilmeli. Maker→checker akışını bozmamalı: Checker onayı önceden verir, yayına geçiş zamanı gelince olur. Payload 3'ün `schedulePublish` + jobs queue özelliği ilk bakılacak yer. OCP'de birden fazla pod (HPA) varsa job'un tek bir yerde koşması gerekir.
- **Saat dilimi (OCP):** Pod'larda `TZ` tanımlı değil (`k8s/configmap.yaml` — clover ve vodafonepaycomtr-site ikisinde de), yani UTC çalışıyorlar. Türkiye UTC+3 olduğu için tarih/saat içeren her şey (zamanlanmış yayın, kampanya başlangıç/bitiş, "aktif mi" kontrolleri) 3 saat kayabilir. Zamanlama işine başlarken `TZ: "Europe/Istanbul"` iki configmap'e de eklenmeli ve tarih karşılaştırmaları bunun üzerinde test edilmeli. DB'de saklanan değer yine UTC/ISO kalmalı, dönüşüm gösterimde yapılmalı.
- **Mobil uygulama kampanyalarının buraya taşınması:** Mobil app'teki kampanyalar da bu CMS'ten yönetilebilir.
- **Form doldurma ile kayıt (register) alma:** Kampanya katılımı için form ve başvuru toplama. Kişisel veri içerdiği için KVKK/aydınlatma metni, saklama süresi ve erişim yetkisi (hangi rol başvuruları görür/dışa aktarır) baştan tasarlanmalı.
- **Kampanya yönetimi:** Katılım, başvuru, dönem ve sonuç takibini içeren daha kapsamlı bir kampanya yönetim ekranı. Kapsamı henüz tanımlı değil, yukarıdaki iki madde ile birlikte netleştirilecek.
