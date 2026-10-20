/*
PROJE: WALMART SATIÞ ANALÝZÝ

AMAÇ:
Maðaza satýþ performansýný, zaman içindeki deðiþimi
ve tatil haftalarýndaki satýþ farklýlýklarýný incelemek.

KULLANILAN TABLOLAR:
dbo.stores         : Maðaza bilgileri
dbo.sales_raw      : Metin olarak aktarýlan ham satýþ verileri
dbo.sales_clean    : Veri tipleri düzeltilmiþ satýþ verileri
dbo.features_raw   : Metin olarak aktarýlan ham ek bilgiler
dbo.features_clean : Veri tipleri düzeltilmiþ ek bilgiler

ÖNEMLÝ:
- Ýlk aktarýlan dbo.sales tablosundaki satýþ tutarlarý hatalýydý.
  Bu dosyada satýþ analizleri için dbo.sales_clean kullanýlýr.
- Her satýþ satýrý bir maðaza-departman-hafta kaydýdýr.
- Departman numaralarýnýn ürün kategorisi karþýlýklarý bilinmiyor.
- NULL, bilinmeyen veya eksik deðerdir; otomatik olarak sýfýr deðildir.
- Haftalýk satýþlar, kayýt tarihinin bulunduðu aya atanýr.
*/

USE WalmartSales;
GO


/* =========================================================
BÖLÜM 1: VERÝ KONTROLLERÝ
========================================================= */


-- SORU 1: Tablolarda kaç kayýt var?
-- Kontrol ettiðimiz sonuçlar:
-- stores = 45, sales_clean = 421570, features_clean = 8190

SELECT COUNT(*) AS MagazaSayisi
FROM dbo.stores;

SELECT COUNT(*) AS SatisSatirSayisi
FROM dbo.sales_clean;

SELECT COUNT(*) AS EkBilgiSatirSayisi
FROM dbo.features_clean;


-- SORU 2: Satýþ verisinin tarih aralýðý ve kapsamý nedir?
-- MIN ve MAX, ilk ve son tarihi bulur.
-- COUNT(DISTINCT), farklý deðerlerin sayýsýný hesaplar.
-- Kontrol ettiðimiz sonuçlar:
-- 2010-02-05 ile 2012-10-26 arasý, 45 maðaza, 81 departman

SELECT
    MIN([Date]) AS IlkTarih,
    MAX([Date]) AS SonTarih,
    COUNT(DISTINCT Store) AS FarkliMagazaSayisi,
    COUNT(DISTINCT Dept) AS FarkliDepartmanSayisi
FROM dbo.sales_clean;


-- SORU 3: Temiz satýþ tablosunda temel alanlar eksik mi?
-- CASE, koþul saðlandýðýnda 1, saðlanmadýðýnda 0 üretir.
-- SUM, eksik kayýtlarýn sayýsýný toplar.
-- Kontrol ettiðimiz sonuç: Bütün sütunlarda 0

SELECT
    SUM(CASE WHEN Store IS NULL THEN 1 ELSE 0 END)
        AS EksikMagaza,
    SUM(CASE WHEN Dept IS NULL THEN 1 ELSE 0 END)
        AS EksikDepartman,
    SUM(CASE WHEN [Date] IS NULL THEN 1 ELSE 0 END)
        AS EksikTarih,
    SUM(CASE WHEN Weekly_Sales IS NULL THEN 1 ELSE 0 END)
        AS EksikSatis,
    SUM(CASE WHEN IsHoliday IS NULL THEN 1 ELSE 0 END)
        AS EksikTatil
FROM dbo.sales_clean;


-- SORU 4: Ýlk satýþ tutarlarý doðru dönüþtürülmüþ mü?
-- Ýlk iki tutarý orijinal CSV ile karþýlaþtýrdýk:
-- 24924.50 ve 46039.49

SELECT TOP (5)
    Store,
    Dept,
    [Date],
    Weekly_Sales,
    IsHoliday
FROM dbo.sales_clean
ORDER BY Store, Dept, [Date];


-- SORU 5: Ek bilgilerde temel alanlar eksik mi?
-- Kontrol ettiðimiz sonuç: Üç sütunda da 0

SELECT
    SUM(CASE WHEN Store IS NULL THEN 1 ELSE 0 END)
        AS EksikMagaza,
    SUM(CASE WHEN [Date] IS NULL THEN 1 ELSE 0 END)
        AS EksikTarih,
    SUM(CASE WHEN IsHoliday IS NULL THEN 1 ELSE 0 END)
        AS EksikTatil
FROM dbo.features_clean;


-- SORU 6: Ek bilgilerde ayný maðaza-hafta tekrarlanýyor mu?
-- GROUP BY, ayný maðaza ve tarihi gruplar.
-- HAVING, birden fazla kaydý bulunan gruplarý seçer.
-- Kontrol ettiðimiz sonuç: Hiç satýr dönmedi.

SELECT
    Store,
    [Date],
    COUNT(*) AS KayitSayisi
FROM dbo.features_clean
GROUP BY Store, [Date]
HAVING COUNT(*) > 1;


-- SORU 7: Ham ek bilgilerde tatil deðerleri nasýl saklanmýþ?
-- Kontrol ettiðimiz sonuç:
-- TRUE = 585, FALSE = 7605
-- Bunlar hafta sayýsý deðil, maðaza-hafta kayýt sayýlarýdýr.

SELECT
    IsHoliday,
    COUNT(*) AS KayitSayisi
FROM dbo.features_raw
GROUP BY IsHoliday;


/* =========================================================
BÖLÜM 2: TABLOLARI BÝRLEÞTÝRME VE EÞLEÞME KONTROLLERÝ
========================================================= */


-- SORU 8: Satýþ, maðaza ve haftalýk ek bilgiler nasýl birleþtirilir?
-- AS, tablolara kýsa ad veya sonuç sütunlarýna baþlýk verir.
-- LEFT JOIN, ek bilgi bulunmasa da satýþ satýrýný korur.
-- Ek bilgiler hem maðaza hem tarih üzerinden eþleþtirilir.

SELECT TOP (10)
    s.Store,                        -- Maðaza numarasý
    st.[Type] AS MagazaTipi,         -- Maðaza tipi
    st.Size AS MagazaBuyuklugu,      -- Maðaza büyüklüðü
    s.Dept,                         -- Departman numarasý
    s.[Date],                       -- Haftalýk kayýt tarihi
    s.Weekly_Sales,                 -- Haftalýk departman satýþý
    s.IsHoliday,                    -- 1 = Tatil, 0 = Normal hafta
    f.Temperature,                  -- Sýcaklýk
    f.Fuel_Price,                   -- Yakýt fiyatý
    f.CPI,                          -- Tüketici fiyat endeksi
    f.Unemployment                  -- Ýþsizlik oraný
FROM dbo.sales_clean AS s
LEFT JOIN dbo.stores AS st
    ON s.Store = st.Store
LEFT JOIN dbo.features_clean AS f
    ON s.Store = f.Store
    AND s.[Date] = f.[Date]
ORDER BY s.Store, s.Dept, s.[Date];


-- SORU 9: Birleþtirme satýrlarý çoðaltýyor mu?
-- Maðaza veya haftalýk ek bilgisi eþleþmeyen satýþ var mý?
-- Kontrol ettiðimiz sonuçlar:
-- Orijinal ve birleþmiþ satýr sayýsý = 421570
-- Eþleþmeyen maðaza ve ek bilgi = 0

SELECT COUNT(*) AS OrijinalSatirSayisi
FROM dbo.sales_clean;

SELECT
    COUNT(*) AS BirlesmisSatirSayisi,
    SUM(CASE WHEN st.Store IS NULL THEN 1 ELSE 0 END)
        AS EslesmeyenMagaza,
    SUM(CASE WHEN f.Store IS NULL THEN 1 ELSE 0 END)
        AS EslesmeyenEkBilgi
FROM dbo.sales_clean AS s
LEFT JOIN dbo.stores AS st
    ON s.Store = st.Store
LEFT JOIN dbo.features_clean AS f
    ON s.Store = f.Store
    AND s.[Date] = f.[Date];


/* =========================================================
BÖLÜM 3: MAÐAZA SATIÞ ANALÝZLERÝ
========================================================= */


-- SORU 10: Toplam satýþý en yüksek 10 maðaza hangileri?
-- SUM, bütün departman ve haftalarýn satýþlarýný toplar.
-- DESC, sonuçlarý büyükten küçüðe sýralar.
-- Bulgumuz: Maðaza 20, 301397792.46 ile ilk sýrada.

SELECT TOP (10)
    Store AS MagazaNo,
    SUM(Weekly_Sales) AS ToplamSatis
FROM dbo.sales_clean
GROUP BY Store
ORDER BY ToplamSatis DESC;


-- SORU 11: Haftalýk ortalama satýþý en yüksek maðazalar hangileri?
-- Toplam satýþ / farklý hafta sayýsý hesaplanýr.
-- NULLIF, sýfýra bölme hatasýný önler.
-- CAST, sonucu iki ondalýk basamakla gösterir.
-- Görünen ilk 10 maðazanýn her birinde 143 hafta bulunuyordu.
-- Maðaza 20'nin haftalýk ortalamasý: 2107676.87

SELECT TOP (10)
    Store AS MagazaNo,
    SUM(Weekly_Sales) AS ToplamSatis,
    COUNT(DISTINCT [Date]) AS HaftaSayisi,
    CAST(
        SUM(Weekly_Sales)
        / NULLIF(COUNT(DISTINCT [Date]), 0)
        AS decimal(18,2)
    ) AS HaftalikOrtalamaSatis
FROM dbo.sales_clean
GROUP BY Store
ORDER BY HaftalikOrtalamaSatis DESC;


-- SORU 12: Satýþ liderlerinin maðaza tipi ve büyüklüðü nedir?
-- Toplama dýþýndaki sonuç sütunlarý GROUP BY içinde bulunur.
-- Bulgumuz: Maðaza 10, bazý büyük A tipi maðazalardan
-- daha yüksek satýþa sahip bir B tipi maðazadýr.

SELECT TOP (10)
    s.Store AS MagazaNo,
    st.[Type] AS MagazaTipi,
    st.Size AS MagazaBuyuklugu,
    SUM(s.Weekly_Sales) AS ToplamSatis,
    CAST(
        SUM(s.Weekly_Sales)
        / NULLIF(COUNT(DISTINCT s.[Date]), 0)
        AS decimal(18,2)
    ) AS HaftalikOrtalamaSatis
FROM dbo.sales_clean AS s
LEFT JOIN dbo.stores AS st
    ON s.Store = st.Store
GROUP BY s.Store, st.[Type], st.Size
ORDER BY ToplamSatis DESC;


-- SORU 13: Büyüklük birimi baþýna haftalýk satýþý
-- en yüksek maðazalar hangileri?
-- Ölçü: Haftalýk ortalama satýþ / maðaza büyüklüðü
-- INNER JOIN, yalnýzca eþleþen maðazalarý getirir.
-- Bulgumuz:
-- Maðaza 43 = 15.4236 ile birinci
-- Maðaza 10 = 15.0138 ile ikinci
-- Maðaza 20 = 10.3448 ile yedinci
-- Bu ölçü satýþ yoðunluðudur; kârlýlýk deðildir.

SELECT TOP (10)
    s.Store AS MagazaNo,
    st.[Type] AS MagazaTipi,
    st.Size AS MagazaBuyuklugu,
    CAST(
        SUM(s.Weekly_Sales)
        / NULLIF(COUNT(DISTINCT s.[Date]), 0)
        AS decimal(18,2)
    ) AS HaftalikOrtalamaSatis,
    CAST(
        SUM(s.Weekly_Sales)
        / NULLIF(COUNT(DISTINCT s.[Date]), 0)
        / NULLIF(st.Size, 0)
        AS decimal(18,4)
    ) AS BuyuklukBasinaHaftalikSatis
FROM dbo.sales_clean AS s
INNER JOIN dbo.stores AS st
    ON s.Store = st.Store
WHERE st.Size > 0
GROUP BY s.Store, st.[Type], st.Size
ORDER BY
    SUM(s.Weekly_Sales)
    / NULLIF(COUNT(DISTINCT s.[Date]), 0)
    / NULLIF(st.Size, 0) DESC;


/* =========================================================
BÖLÜM 4: ZAMAN ÝÇÝNDE SATIÞ DEÐÝÞÝMÝ
========================================================= */


-- SORU 14: Aylýk toplam ve haftalýk ortalama satýþlar nasýl deðiþiyor?
-- YEAR ve MONTH, tarihten yýl ve ay bilgisini alýr.
-- Aylarda dört veya beþ haftalýk kayýt bulunabilir.
-- Haftalýk ortalama, bu sayý farkýný dikkate almamýzý saðlar.
-- Bulgumuz: 2010 ve 2011 Aralýk ortalamalarý yaklaþýk 57.7 milyon.
-- Veri 2010 Þubat'ta baþlar ve 2012 Ekim'de biter.

SELECT
    YEAR([Date]) AS Yil,
    MONTH([Date]) AS Ay,
    SUM(Weekly_Sales) AS ToplamSatis,
    COUNT(DISTINCT [Date]) AS HaftaSayisi,
    CAST(
        SUM(Weekly_Sales)
        / NULLIF(COUNT(DISTINCT [Date]), 0)
        AS decimal(18,2)
    ) AS HaftalikOrtalamaSatis
FROM dbo.sales_clean
GROUP BY YEAR([Date]), MONTH([Date])
ORDER BY Yil, Ay;


-- SORU 15: Ayný ayýn haftalýk ortalama satýþý,
-- önceki yýla göre yüzde kaç deðiþmiþ?
-- CTE, sorgu içinde kullanýlan isimlendirilmiþ bir sonuç kümesidir.
-- Ayný CTE'yi kendisiyle eþleþtirerek önceki yýlý getiriyoruz.
-- Bulgumuz: 2012'nin mevcut tüm aylarýnda deðiþim pozitif.
-- 2012 Nisan'daki deðiþim: %4.25
-- Aylarýn hafta ve tatil daðýlýmlarý farklý olabilir.

;WITH AylikSatis AS (
    SELECT
        YEAR([Date]) AS Yil,
        MONTH([Date]) AS Ay,
        SUM(Weekly_Sales)
        / NULLIF(COUNT(DISTINCT [Date]), 0)
            AS HaftalikOrtalamaSatis
    FROM dbo.sales_clean
    GROUP BY YEAR([Date]), MONTH([Date])
)
SELECT
    bu.Yil,
    bu.Ay,
    CAST(bu.HaftalikOrtalamaSatis AS decimal(18,2))
        AS BuYilHaftalikOrtalama,
    CAST(onceki.HaftalikOrtalamaSatis AS decimal(18,2))
        AS OncekiYilHaftalikOrtalama,
    CAST(
        (
            bu.HaftalikOrtalamaSatis
            / NULLIF(onceki.HaftalikOrtalamaSatis, 0)
            - 1
        ) * 100
        AS decimal(10,2)
    ) AS DegisimYuzdesi
FROM AylikSatis AS bu
INNER JOIN AylikSatis AS onceki
    ON bu.Ay = onceki.Ay
    AND bu.Yil = onceki.Yil + 1
ORDER BY bu.Yil, bu.Ay;


/* =========================================================
BÖLÜM 5: TATÝL HAFTASI ANALÝZLERÝ
========================================================= */


-- SORU 16: Tatil ve normal haftalarda ortalama satýþ farklý mý?
-- Önce bütün maðazalarýn satýþlarýný hafta bazýnda topluyoruz.
-- Sonra haftalýk toplamlarýn ortalamasýný hesaplýyoruz.
-- Bulgumuz:
-- 133 normal hafta ortalamasý = 46856537.11
-- 10 tatil haftasý ortalamasý = 50529955.16
-- Tatil ortalamasý yaklaþýk %7.84 daha yüksek.
-- Bu iliþki, tek baþýna nedensellik göstermez.

;WITH HaftalikSatis AS (
    SELECT
        [Date],
        IsHoliday,
        SUM(Weekly_Sales) AS HaftalikToplamSatis
    FROM dbo.sales_clean
    GROUP BY [Date], IsHoliday
)
SELECT
    CASE
        WHEN IsHoliday = 1 THEN 'Tatil haftasi'
        ELSE 'Normal hafta'
    END AS HaftaTuru,
    COUNT(*) AS HaftaSayisi,
    CAST(
        AVG(HaftalikToplamSatis)
        AS decimal(18,2)
    ) AS OrtalamaHaftalikSatis
FROM HaftalikSatis
GROUP BY IsHoliday
ORDER BY IsHoliday;


-- SORU 17: Tatil-normal hafta yüzde farký hangi maðazalarda yüksek?
-- AVG(CASE...), yalnýzca ilgili gruptaki deðerlerin ortalamasýný alýr.
-- AVG, CASE sonucunda oluþan NULL deðerleri hesaba katmaz.
-- Bulgumuz:
-- Maðaza 7 = %19.44
-- Maðaza 35 = %18.31
-- Maðaza 15 = %14.48

;WITH MagazaHaftalik AS (
    SELECT
        Store,
        [Date],
        IsHoliday,
        SUM(Weekly_Sales) AS HaftalikSatis
    FROM dbo.sales_clean
    GROUP BY Store, [Date], IsHoliday
),
MagazaOrtalama AS (
    SELECT
        Store,
        AVG(CASE WHEN IsHoliday = 0 THEN HaftalikSatis END)
            AS NormalHaftaOrtalamasi,
        AVG(CASE WHEN IsHoliday = 1 THEN HaftalikSatis END)
            AS TatilHaftasiOrtalamasi
    FROM MagazaHaftalik
    GROUP BY Store
)
SELECT TOP (10)
    Store AS MagazaNo,
    CAST(NormalHaftaOrtalamasi AS decimal(18,2))
        AS NormalHaftaOrtalamasi,
    CAST(TatilHaftasiOrtalamasi AS decimal(18,2))
        AS TatilHaftasiOrtalamasi,
    CAST(
        (
            TatilHaftasiOrtalamasi
            / NULLIF(NormalHaftaOrtalamasi, 0) - 1
        ) * 100
        AS decimal(10,2)
    ) AS TatilFarkiYuzdesi
FROM MagazaOrtalama
ORDER BY
    TatilHaftasiOrtalamasi
    / NULLIF(NormalHaftaOrtalamasi, 0) DESC;


-- SORU 18: Tatil-normal hafta yüzde farký hangi departmanlarda yüksek?
-- Yalnýzca 133 normal ve 10 tatil haftasýnda kaydý bulunanlarý seçiyoruz.
-- Böylece kýsa dönemli kayýtlarýn etkisini azaltýyoruz.
-- Bulgumuz: Departman 18, %114.86 ile ilk sýrada.
-- Bu filtre, her maðazada eksiksiz kayýt bulunduðunu garanti etmez.

;WITH DepartmanHaftalik AS (
    SELECT
        Dept,
        [Date],
        IsHoliday,
        SUM(Weekly_Sales) AS HaftalikSatis
    FROM dbo.sales_clean
    GROUP BY Dept, [Date], IsHoliday
),
DepartmanOrtalama AS (
    SELECT
        Dept,
        AVG(CASE WHEN IsHoliday = 0 THEN HaftalikSatis END)
            AS NormalHaftaOrtalamasi,
        AVG(CASE WHEN IsHoliday = 1 THEN HaftalikSatis END)
            AS TatilHaftasiOrtalamasi,
        COUNT(CASE WHEN IsHoliday = 0 THEN 1 END)
            AS NormalHaftaSayisi,
        COUNT(CASE WHEN IsHoliday = 1 THEN 1 END)
            AS TatilHaftaSayisi
    FROM DepartmanHaftalik
    GROUP BY Dept
)
SELECT TOP (10)
    Dept AS DepartmanNo,
    NormalHaftaSayisi,
    TatilHaftaSayisi,
    CAST(NormalHaftaOrtalamasi AS decimal(18,2))
        AS NormalHaftaOrtalamasi,
    CAST(TatilHaftasiOrtalamasi AS decimal(18,2))
        AS TatilHaftasiOrtalamasi,
    CAST(
        (
            TatilHaftasiOrtalamasi
            / NULLIF(NormalHaftaOrtalamasi, 0) - 1
        ) * 100
        AS decimal(10,2)
    ) AS TatilFarkiYuzdesi
FROM DepartmanOrtalama
WHERE NormalHaftaOrtalamasi > 0
    AND NormalHaftaSayisi = 133
    AND TatilHaftaSayisi = 10
ORDER BY
    TatilHaftasiOrtalamasi
    / NULLIF(NormalHaftaOrtalamasi, 0) DESC;


-- SORU 19: Yüzde yerine tutar farkýyla sýralayýnca ne deðiþiyor?
-- Tatil ortalamasýndan normal hafta ortalamasýný çýkarýyoruz.
-- Bulgumuz:
-- Departman 72 tutar farkýnda ilk sýrada: 2035785.01
-- Yüzde farkýnda lider departman 18 idi.
-- Yüksek yüzde farký, en yüksek tutar farký anlamýna gelmez.

;WITH DepartmanHaftalik AS (
    SELECT
        Dept,
        [Date],
        IsHoliday,
        SUM(Weekly_Sales) AS HaftalikSatis
    FROM dbo.sales_clean
    GROUP BY Dept, [Date], IsHoliday
),
DepartmanOrtalama AS (
    SELECT
        Dept,
        AVG(CASE WHEN IsHoliday = 0 THEN HaftalikSatis END)
            AS NormalHaftaOrtalamasi,
        AVG(CASE WHEN IsHoliday = 1 THEN HaftalikSatis END)
            AS TatilHaftasiOrtalamasi,
        COUNT(CASE WHEN IsHoliday = 0 THEN 1 END)
            AS NormalHaftaSayisi,
        COUNT(CASE WHEN IsHoliday = 1 THEN 1 END)
            AS TatilHaftaSayisi
    FROM DepartmanHaftalik
    GROUP BY Dept
)
SELECT TOP (10)
    Dept AS DepartmanNo,
    NormalHaftaSayisi,
    TatilHaftaSayisi,
    CAST(NormalHaftaOrtalamasi AS decimal(18,2))
        AS NormalHaftaOrtalamasi,
    CAST(TatilHaftasiOrtalamasi AS decimal(18,2))
        AS TatilHaftasiOrtalamasi,
    CAST(
        TatilHaftasiOrtalamasi - NormalHaftaOrtalamasi
        AS decimal(18,2)
    ) AS HaftalikSatisFarki,
    CAST(
        (
            TatilHaftasiOrtalamasi
            / NULLIF(NormalHaftaOrtalamasi, 0) - 1
        ) * 100
        AS decimal(10,2)
    ) AS TatilFarkiYuzdesi
FROM DepartmanOrtalama
WHERE NormalHaftaOrtalamasi > 0
    AND NormalHaftaSayisi = 133
    AND TatilHaftaSayisi = 10
ORDER BY
    TatilHaftasiOrtalamasi - NormalHaftaOrtalamasi DESC;


/* =========================================================
BÖLÜM 6: DEPARTMAN 72 VE ZÝRVE HAFTALAR
========================================================= */


-- SORU 20: Departman 72'nin hangi tatil haftalarýnda satýþý yüksek?
-- Maðaza sayýsýný da göstererek haftalýk kapsamý inceliyoruz.
-- Bulgumuz:
-- 2010-11-26 = 10533640.92
-- 2011-11-25 = 10089704.42
-- Kayýt bulunan maðaza sayýsý haftalara göre 41-43 arasýnda.

SELECT
    [Date] AS HaftaTarihi,
    COUNT(DISTINCT Store) AS MagazaSayisi,
    SUM(Weekly_Sales) AS HaftalikToplamSatis
FROM dbo.sales_clean
WHERE Dept = 72
    AND IsHoliday = 1
GROUP BY [Date]
ORDER BY HaftalikToplamSatis DESC;


-- SORU 21: Her tatil haftasýnýn toplam tatil satýþýndaki payý nedir?
-- SUM(...) OVER (), satýrlarý birleþtirmeden genel toplamý getirir.
-- Her haftanýn satýþýný bu toplama bölerek payýný hesaplýyoruz.
-- Bulgumuz:
-- 2010-11-26 = %26.13
-- 2011-11-25 = %25.03
-- Ýki haftanýn toplam payý yaklaþýk %51.16.

;WITH TatilHaftalari AS (
    SELECT
        [Date],
        COUNT(DISTINCT Store) AS MagazaSayisi,
        SUM(Weekly_Sales) AS HaftalikToplamSatis
    FROM dbo.sales_clean
    WHERE Dept = 72
        AND IsHoliday = 1
    GROUP BY [Date]
)
SELECT
    [Date] AS HaftaTarihi,
    MagazaSayisi,
    HaftalikToplamSatis,
    CAST(
        100.0 * HaftalikToplamSatis
        / NULLIF(SUM(HaftalikToplamSatis) OVER (), 0)
        AS decimal(10,2)
    ) AS TatilSatisindakiPayYuzdesi
FROM TatilHaftalari
ORDER BY HaftalikToplamSatis DESC;


-- SORU 22: Ýki zirve hafta hariç tutulduðunda ortalama nasýl deðiþiyor?
-- NOT IN, belirtilen iki tarihi hesaplamanýn dýþýnda býrakýr.
-- Veriden herhangi bir kayýt silinmez.
-- Bu bir duyarlýlýk kontrolüdür.
--
-- Kontrol ettiðimiz sonuçlar:
-- Normal hafta ortalamasý           = 1995575.54
-- Tüm tatil haftalarý ortalamasý    = 4031360.55
-- Ýki zirve hariç tatil ortalamasý  = 2461282.52
--
-- YORUM:
-- Ýki hafta hariç tutulunca normal haftalara göre ortalama
-- satýþ farký %102.01'den yaklaþýk %23.34'e geriliyor.
-- Yüksek tatil ortalamasý özellikle iki kasým haftasýndan etkileniyor.
-- Maðaza kapsamýndaki farklýlýklar ve mevsimsellik de dikkate alýnmalý.
-- Bu karþýlaþtýrma tek baþýna nedensellik göstermez.

;WITH HaftalikSatis AS (
    SELECT
        [Date],
        IsHoliday,
        SUM(Weekly_Sales) AS HaftalikSatis
    FROM dbo.sales_clean
    WHERE Dept = 72
    GROUP BY [Date], IsHoliday
)
SELECT
    CAST(
        AVG(CASE WHEN IsHoliday = 0 THEN HaftalikSatis END)
        AS decimal(18,2)
    ) AS NormalHaftaOrtalamasi,

    CAST(
        AVG(CASE WHEN IsHoliday = 1 THEN HaftalikSatis END)
        AS decimal(18,2)
    ) AS TumTatilHaftalariOrtalamasi,

    CAST(
        AVG(
            CASE
                WHEN IsHoliday = 1
                    AND [Date] NOT IN ('20101126', '20111125')
                THEN HaftalikSatis
            END
        )
        AS decimal(18,2)
    ) AS IkiZirveHaricTatilOrtalamasi
FROM HaftalikSatis;