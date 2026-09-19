/**
 * 19.09.2026 — starting content of the Çerez Bandı global, word for word the
 * cookie banner Vodafone Türkiye runs on vodafone.com.tr (OneTrust, read
 * 19.09.2026). vodafonepay.com.tr itself shows no banner yet; the user chose
 * "vodafone.com.tr'dekinin aynısı" for the clone.
 *
 * Inserted as data by migration §17, not as field defaultValues (Payload
 * would bake these long texts into column DEFAULTs — see globals/SeoFiles.ts).
 * The site keeps its own copy as a fallback for an empty field.
 */

export const COOKIE_CATEGORY_KEYS = ["necessary", "performance", "functional", "marketing"] as const;
export type CookieCategoryKey = (typeof COOKIE_CATEGORY_KEYS)[number];

export const COOKIE_CONSENT_DEFAULTS = {
  title: "Çerez ayarlarınızı yönetin",
  policyLinkLabel: "Çerez Politikamız",
  policyLinkUrl: "/cerez-politikasi",
  introText:
    "'da ayrıntılı şekilde açıkladığımız üzere zorunlu çerezlerin kullanılması, internet sitemizin çalışması ve güvenliği için gereklidir. Bunlar dışında kalan araçların kullanılması müşterilerimizin hizmetlerimizi nasıl kullandıklarını anlamak, onlara özel teklifler sunmak (örneğin; site ziyaretlerini ölçerek) ve internet sitesinde iyileştirmeler yapabilmek için kullanıyoruz. “Çerezleri kabul et”e tıklayarak sizlere özel olan iletişimlerimizin tümünü kabul etmiş olacaksınız.",
  rejectLabel: "Reddet",
  rejectText: "seçeneğine tıklayarak çerezleri kabul etmeden devam edebilir ya da siteye çerez ayarlarını değiştirerek devam etmek için",
  settingsLinkLabel: "buraya tıklayabilirsiniz.",
  acceptLabel: "Çerezleri kabul et",
  pcTitle: "Gizliliğiniz",
  pcDescription: [
    "Herhangi bir internet sitesini ziyaret ettiğinizde, sitenin işlevlerinden en iyi şekilde faydalanabilmeniz için kullandığınız tarayıcı üzerinden genellikle “tanımlama bilgileri” başlığı altında çeşitli bilgiler alınabilir ve depolanabilir.",
    "Söz konusu bilgiler kullanım tercihleriniz veya kullandığınız cihaz hakkında olabilir veya sitenin doğru ve beklediğiniz şekilde çalıştırılabilmesi için kullanılabilir.",
    "Bilgiler çoğunlukla sizi doğrudan ve kişisel olarak tanımlamaz; ancak size ve kullanım alışkanlıklarınıza daha uygun bir internet deneyimi sunarak, internet sitemizden en kapsamlı şekilde faydalanmanızı sağlar.",
    "Bazı tanımlama bilgisi tiplerinin sitemiz tarafından kullanılmasına izin vermemeyi tercih edebilirsiniz. Ancak bu durumda sitemizdeki deneyiminizin ve size sunacağımız bazı hizmetlerin bu tercihinizden olumsuz şekilde etkilenebileceğini hatırlatmak isteriz.",
    "Tanımlama bilgisi kategorileri hakkında daha fazla bilgi almak ve sitemizden en iyi şekilde faydalanabilmeniz için önceden belirlediğimiz ayarları değiştirmek için aşağıdaki kategori başlıklarına tıklayabilirsiniz.",
  ].join("\n\n"),
  moreInfoLabel: "Daha Fazla Bilgi",
  moreInfoUrl: "/cerez-politikasi",
  allowAllLabel: "Tümüne İzin Ver",
  manageTitle: "Çerez Ayarlarınızı Yönetin",
  alwaysActiveLabel: "Her Zaman Etkin",
  saveLabel: "Ayarları Kaydet",
  categories: [
    {
      key: "necessary" as CookieCategoryKey,
      title: "Zorunlu Çerezler",
      description:
        "Bu kategorideki çerezler, Site’nin doğru şekilde çalışması ve kullanılabilmesi için gereklidir.\n\nBu çerezlerin kullanımı esnasında gerçekleştirdiğimiz veri işleme faaliyetleri için Kanun m.5/2-c “Bir sözleşmenin kurulması veya ifasıyla doğrudan doğruya ilgili olması kaydıyla, sözleşmenin taraflarına ait kişisel verilerin işlenmesinin gerekli olması” ve Kanun madde 5/2-f kapsamında “İlgili kişinin temel hak ve özgürlüklerine zarar vermemek kaydıyla, veri sorumlusunun meşru menfaatleri için veri işlenmesinin zorunlu olması” hukuki sebebine dayanılmaktadır.",
    },
    {
      key: "performance" as CookieCategoryKey,
      title: "Performans (Analitik) Çerezleri",
      description:
        "Kullanıcıların internet sitesini nasıl kullandıkları hakkında bilgi toplayan çerezlerdir. Bu kategorideki çerezler sayesinde, Sitenin performansının nasıl artırabileceğimizi analiz ederiz. Bu çerezlerin kullanımı esnasında gerçekleştirdiğimiz veri işleme faaliyetleri için Kanun madde 5/1 kapsamında “açık rıza” hukuki sebebine dayanılmaktadır.",
    },
    {
      key: "functional" as CookieCategoryKey,
      title: "İşlevsel Çerezler",
      description:
        "Bu kategorideki çerezler, internet sitesindeki kullanım tercihlerinizi hatırlamak ve site kullanımınızı kişiselleştirmek amacıyla kullanılan çerezlerdir. Bu çerezler, kullanım deneyiminizi geliştirebilmemize yararlar. Örneğin, sepetinize daha önceki ziyaretinizde hangi ürünleri attığınızı kaydederek kaldığınız yerden devam edebilmenizi sağlayabiliriz.\n\nBu çerezlerin kullanımı esnasında gerçekleştirdiğimiz veri işleme faaliyetleri için Kanun madde 5/1 kapsamında “açık rıza” hukuki sebebine dayanılmaktadır.",
    },
    {
      key: "marketing" as CookieCategoryKey,
      title: "Reklam/Pazarlama Çerezleri",
      description:
        "Bu kategoride yer alan çerezler, Kullanıcıların ilgi alanlarına göre kişiselleştirilmiş içerik sunmak ve pazarlama faaliyetlerinin etkinliğini ölçmek için kullanılır. Bunlar, ilgili şirketler tarafından ilgi alanlarına yönelik profilinizi oluşturmak ve diğer sitelerde bu ilgi alanlarıyla alakalı reklamları göstermek amacıyla kullanılabilir.\n\nBu bilgiler tarayıcınızı ve cihazınızı tekil olarak belirleyerek çalışırlar. Bu çerezlere izin vermediğiniz takdirde farklı internet sitelerinde size özel bir reklam deneyimi sunamayacağımızı hatırlatmak isteriz. Bu çerezlerin kullanımı esnasında gerçekleştirdiğimiz veri işleme faaliyetleri için Kanun madde 5/1 kapsamında “açık rıza” hukuki sebebine dayanılmaktadır.",
    },
  ],
};

/** Every category key at most once, and "necessary" present (it can't be turned off, so it must be listed). */
export function validateCookieCategories(value: unknown, locale: "tr" | "en"): true | string {
  const rows = Array.isArray(value) ? (value as { key?: string }[]) : [];
  const keys = rows.map((r) => r?.key).filter(Boolean) as string[];
  const dup = keys.find((k, i) => keys.indexOf(k) !== i);
  if (dup) return locale === "en" ? `Each category can be listed once ("${dup}" appears twice).` : `Her kategori bir kez eklenebilir ("${dup}" iki kez var).`;
  if (!keys.includes("necessary")) return locale === "en" ? "The 'Necessary' category must stay in the list." : "'Zorunlu' kategorisi listeden çıkarılamaz.";
  return true;
}
