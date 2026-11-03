# LIQ-REC — çalıştırma rehberi

Bu depo, **Forecasting Liquidity-Stress Recovery with a Guarded Cox Correction** çalışmasının kodlarını içerir. Çağlar Sözen ve Mervenur Sözen.

RStudio çalışma klasörünü bu deponun ana klasörü yapın. İlk kurulum ve kısa kontrol:

```r
source("00_INSTALL.R", encoding = "UTF-8")
source("00_START.R", encoding = "UTF-8")
source("01_QUICK_CHECK.R", encoding = "UTF-8")
```

`00_START.R` yalnız fonksiyonları yükler. Uzun tahmin çalışmasını veya veri indirmeyi başlatmaz.

| Amaç | Dosya |
|---|---|
| Tek sentetik örnek | `02_RUN_EXAMPLE.R` |
| 12 denemelik pilot | `03_RUN_PILOT.R` |
| Altı senaryoda toplam 600 tekrar | `04_RUN_SIMULATION.R` |
| Ana tarihsel örneklem ve rolling çalışmalar | `05_RUN_MARKET.R` |
| Etkin ayarları dışa aktarma | `06_EXPORT_SPECIFICATION.R` |
| Eski çıktılarda CITL raporlama düzeltmesi | `07_REPAIR_ARCHIVED_CITL.R` |
| İzinli yerel veri paketini kurma | `08_INSTALL_SNAPSHOT.R` |

Tam simülasyon için önce güncel kaynakla pilot çalışmalıdır. Simülasyonun Yahoo Finance verisine ihtiyacı yoktur. Tarihsel çalışma için korunmuş veri sürümünü kendi yerel arşivinizden kurun:

```r
Sys.setenv(LIQ_SNAPSHOT_ARCHIVE = "C:/klasor/LIQ_REC_SNBE_Final_20261103.zip")
source("08_INSTALL_SNAPSHOT.R", encoding = "UTF-8")
source("05_RUN_MARKET.R", encoding = "UTF-8")
```

Ham sağlayıcı verisi GitHub'da dağıtılmaz. Sağlanan yerel ZIP'ten yalnız gerekli veri ve envanter dosyaları alınır; dosya kimlikleri doğrulanır. Farklı bir veri sürümü mevcut dosyaların üzerine yazılmaz.

Tarihsel giriş noktası, kurulmuş dört dosyanın boyut ve MD5 kimliklerini depodaki beklenen kayıtlarla ayrıca karşılaştırır. Veri ile kilit dosyasını birlikte değiştirmek bu kontrolü geçirmez. Numaralı deneyler, önceki oturumdan kalan farklı üyelik, envanter ve bağlam dosyası ayarlarını geçici olarak temizleyerek sabit çalışma profillerini kullanır; işlem sonrasında eski oturum ayarları geri yüklenir. `06_EXPORT_SPECIFICATION.R`, pilot, tam simülasyon, tarihsel çalışma ve örneğin etkin ayarlarını ayrı dosyalara yazar.

Python ile mevcut sayısal kayıtları kontrol etmek ve şekilleri yeniden çizmek:

```sh
python scripts/verify_reference.py
python -m pip install -r requirements-figures.txt
python scripts/reproduce_figures.py
```

Üretilen dosyalar `results/` altında oluşur. Mevcut sayısal tabloları kontrol etmek ya da şekilleri çizmek, R modellerini yeniden eğitmek veya 600 tekrarlı deneyi yeniden çalıştırmak değildir.

Korunmuş bilimsel kaynak 4.8.0 sürümüdür. Yeni başlangıç dosyaları bu kaynağı değiştirmez. CITL düzeltmesi yalnız raporlanan kalibrasyon sabitine uygulanır; tahmin olasılıkları ve seçim kararları korunur. R'nin eski BSS sütunları kalibre edilmiş referansları kullanır. Makaledeki ham eğitim referanslı beceri puanları `scripts/summarize_run.py` ile ayrı ve açık isimli sütunlarda hesaplanır.

Tarihsel kazanç %1.13 düzeyinde ve belirsizdir; sekiz destekli rolling pencerede LIQ-P, Cox'a eşittir. Non-proportional-hazards simülasyonundaki Cox'a göre kazanç %5.88'dir; lojite karşı düzeltilmiş Brier üstünlüğü gösterilmez. Açık ek deneyler ve yeniden üretim sınırları İngilizce README ile teknik belgelerde belirtilir.

4 Kasım 2026 kod denetiminin kapsamı ve yapılan başlangıç katmanı düzeltmeleri `documentation/CODE_REVIEW.md` dosyasındadır. Arayüz 1.0.1; korunmuş bilimsel model 4.8.0 sürümündedir.
