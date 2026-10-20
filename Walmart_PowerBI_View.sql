-- Görünümü oluþturacaðýmýz veritabanýný seçiyoruz.
USE WalmartSales;
GO

-- Satýþ, maðaza ve haftalýk ek bilgileri birleþtiren görünümü oluþturuyoruz.
-- Görünüm zaten varsa ALTER bölümü mevcut tanýmýný günceller.
CREATE OR ALTER VIEW dbo.vw_WalmartSales
AS
SELECT
    s.Store,                    -- Maðaza numarasý
    st.[Type] AS StoreType,      -- Maðaza tipi
    st.Size AS StoreSize,        -- Maðaza büyüklüðü
    s.Dept,                     -- Departman numarasý
    s.[Date],                   -- Haftalýk kayýt tarihi
    s.Weekly_Sales,             -- Haftalýk departman satýþ tutarý
    s.IsHoliday,                -- 1 = Tatil, 0 = Normal hafta
    f.Temperature,              -- Sýcaklýk
    f.Fuel_Price,               -- Yakýt fiyatý
    f.MarkDown1,                -- Ýndirim bilgileri
    f.MarkDown2,
    f.MarkDown3,
    f.MarkDown4,
    f.MarkDown5,
    f.CPI,                      -- Tüketici fiyat endeksi
    f.Unemployment              -- Ýþsizlik oraný

FROM dbo.sales_clean AS s

-- Maðaza bilgilerini ekliyoruz.
LEFT JOIN dbo.stores AS st
    ON s.Store = st.Store

-- Ek bilgileri ayný maðaza ve haftaya göre eþleþtiriyoruz.
LEFT JOIN dbo.features_clean AS f
    ON s.Store = f.Store
    AND s.[Date] = f.[Date];
GO

-- Görünümün satýr sayýsýný kontrol ediyoruz.
-- Beklenen sonuç: 421570
SELECT COUNT(*) AS GorunumSatirSayisi
FROM dbo.vw_WalmartSales;

-- Görünümdeki ilk 5 kaydý inceliyoruz.
SELECT TOP (5) *
FROM dbo.vw_WalmartSales
ORDER BY Store, Dept, [Date];