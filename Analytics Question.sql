--Business Analytics Questions
-- 1. Top Providers by RTP (Return to Player)

--Question: Which game providers offer the highest average RTP?

-- SQL Outline:

SELECT dp.Provider, 
       AVG(f.RTP) AS AvgRTP
FROM FactCasinoGames f
JOIN DimProvider dp ON f.ProviderID = dp.ProviderID
GROUP BY dp.Provider
ORDER BY AvgRTP DESC;


SELECT * 
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME LIKE 'Dim%';

--2. Revenue Potential by Provider
SELECT dp.Provider, AVG(f.RTP) AS AvgRTP, AVG(f.Max_Win) AS AvgMaxWin
FROM FactCasinoGames f
JOIN DimProvider dp ON f.ProviderID = dp.ProviderID
GROUP BY dp.Provider
ORDER BY AvgRTP DESC;
--Insight: Which providers offer the most player‑friendly games?

--3.Regional Game Preferences, Which regions have the highest proportion of jackpot games?
SELECT dr.Country_Availability, 
       COUNT(*) AS TotalGames,
       SUM(CASE WHEN f.Jackpot = 'Yes' THEN 1 ELSE 0 END) AS JackpotGames
FROM FactCasinoGames f
JOIN DimRegion dr ON f.RegionID = dr.RegionID
GROUP BY dr.Country_Availability
ORDER BY JackpotGames DESC;



