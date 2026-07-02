--Script: 05_Update_Automation.sql

--Purpose: Incremental updates to fact/dimension tables.
--Batch File: Casino_ETL.bat (calls sqlcmd).
--Scheduler: Windows Task Scheduler job.
--Logging: ETL_Log table to track runs.

--Update Each Dimension
-- Update DimGame
INSERT INTO DimGame (Game)
SELECT DISTINCT cg.Game
FROM CasinoGames cg
LEFT JOIN DimGame g ON cg.Game = g.Game
WHERE g.Game IS NULL;

-- Update DimCasino
INSERT INTO DimCasino (Casino)
SELECT DISTINCT cg.Casino
FROM CasinoGames cg
LEFT JOIN DimCasino c ON cg.Casino = c.Casino
WHERE c.Casino IS NULL;

-- Update DimProvider
INSERT INTO DimProvider (Provider)
SELECT DISTINCT cg.Provider
FROM CasinoGames cg
LEFT JOIN DimProvider p ON cg.Provider = p.Provider
WHERE p.Provider IS NULL;

-- Update DimCurrency
INSERT INTO DimCurrency (Currency)
SELECT DISTINCT cg.Currency
FROM CasinoGames cg
LEFT JOIN DimCurrency cu ON cg.Currency = cu.Currency
WHERE cu.Currency IS NULL;

-- Update DimVolatility
INSERT INTO DimVolatility (Volatility)
SELECT DISTINCT cg.Volatility
FROM CasinoGames cg
LEFT JOIN DimVolatility v ON cg.Volatility = v.Volatility
WHERE v.Volatility IS NULL;

-- Update DimDate with new years from CasinoGames
INSERT INTO DimDate (Year)
SELECT DISTINCT cg.Release_Year
FROM CasinoGames cg
LEFT JOIN DimDate d ON cg.Release_Year = d.Year
WHERE d.Year IS NULL;

-- Update DimRegulation
INSERT INTO DimRegulation (License_Jurisdiction)
SELECT DISTINCT cg.License_Jurisdiction
FROM CasinoGames cg
LEFT JOIN DimRegulation r ON cg.License_Jurisdiction = r.License_Jurisdiction
WHERE r.License_Jurisdiction IS NULL;

-- Update DimRegion
INSERT INTO DimRegion (Country_Availability)
SELECT DISTINCT cg.Country_Availability
FROM CasinoGames cg
LEFT JOIN DimRegion rg ON cg.Country_Availability = rg.Country_Availability
WHERE rg.Country_Availability IS NULL;

-- Update DimLanguage with new languages from CasinoGames
INSERT INTO DimLanguage (Language)
SELECT DISTINCT cg.Languages
FROM CasinoGames cg
LEFT JOIN DimLanguage l ON cg.Languages = l.Language
WHERE l.Language IS NULL;

-- Finally update FactCasinoGames
INSERT INTO FactCasinoGames (
    GameID, CasinoID, ProviderID, CurrencyID, VolatilityID,
    DateID, RegulationID, RegionID, LanguageID,
    RTP, Jackpot, Min_Bet, Max_Win, Max_Multiplier
)
SELECT g.GameID, c.CasinoID, p.ProviderID, cu.CurrencyID, v.VolatilityID,
       d.DateID, r.RegulationID, rg.RegionID, l.LanguageID,
       cg.RTP, cg.Jackpot, cg.Min_Bet, cg.Max_Win, cg.Max_Multiplier
FROM CasinoGames cg
JOIN DimGame g ON cg.Game = g.Game
JOIN DimCasino c ON cg.Casino = c.Casino
JOIN DimProvider p ON cg.Provider = p.Provider
JOIN DimCurrency cu ON cg.Currency = cu.Currency
JOIN DimVolatility v ON cg.Volatility = v.Volatility
JOIN DimRegulation r ON cg.License_Jurisdiction = r.License_Jurisdiction
JOIN DimRegion rg ON cg.Country_Availability = rg.Country_Availability
JOIN DimLanguage l ON cg.Languages = l.Language
JOIN DimDate d ON cg.Release_Year = d.Year;

PRINT 'Starting ETL update for DimGame...';

-- Insert new games into DimGame
INSERT INTO DimGame (Game)
SELECT DISTINCT cg.Game
FROM CasinoGames cg
LEFT JOIN DimGame g ON cg.Game = g.Game
WHERE g.Game IS NULL;

PRINT 'Insert completed.';

-- Show how many rows were inserted
SELECT COUNT(*) AS NewGamesInserted
FROM CasinoGames cg
LEFT JOIN DimGame g ON cg.Game = g.Game
WHERE g.Game IS NULL;

PRINT 'ETL update for DimGame finished successfully.';
