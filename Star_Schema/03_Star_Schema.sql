--Star Schema Creation
--Script: 04_Star_Schema.sql

--Purpose: Creates fact and dimension tables.


-- Create Tables  Star schema via ETL
--Extract from RawCasinoGames.

--Transform into fact vs dimension attributes.

--Load into new tables.

--1. Create Dimensions
-- Providers
USE CasinoAnalytics;
GO
-- Drop old dimension tables if they exist
IF OBJECT_ID('DimGame', 'U') IS NOT NULL DROP TABLE DimGame;
IF OBJECT_ID('DimCasino', 'U') IS NOT NULL DROP TABLE DimCasino;
IF OBJECT_ID('DimProvider', 'U') IS NOT NULL DROP TABLE DimProvider;
IF OBJECT_ID('DimCurrency', 'U') IS NOT NULL DROP TABLE DimCurrency;
IF OBJECT_ID('DimVolatility', 'U') IS NOT NULL DROP TABLE DimVolatility;
IF OBJECT_ID('DimDate', 'U') IS NOT NULL DROP TABLE DimDate;
IF OBJECT_ID('DimRegulation', 'U') IS NOT NULL DROP TABLE DimRegulation;
IF OBJECT_ID('DimRegion', 'U') IS NOT NULL DROP TABLE DimRegion;
IF OBJECT_ID('DimLanguage', 'U') IS NOT NULL DROP TABLE DimLanguage;

-- Drop old fact table if it exists
IF OBJECT_ID('FactCasinoGames', 'U') IS NOT NULL DROP TABLE FactCasinoGames;


SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE';

USE CasinoAnalytics;
GO

SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'CasinoGames';

--Dimension Tables
--1. Create DimCasino , This dimension will store casino names.
USE CasinoAnalytics;
GO
CREATE TABLE DimGame (
    GameID INT PRIMARY KEY,              -- natural key from CasinoGames
    Game NVARCHAR(200),
    Game_Type NVARCHAR(100),
    Game_Category NVARCHAR(100),
    Release_Year INT,
    Languages NVARCHAR(500),             -- or normalize into DimLanguage bridge
    Mobile_Compatible BIT,
    Free_Spins_Feature BIT,
    Bonus_Buy_Available BIT,
    Jackpot NVARCHAR(50)
);
INSERT INTO DimGame (
    GameID, Game, Game_Type, Game_Category, Release_Year,
    Languages, Mobile_Compatible, Free_Spins_Feature,
    Bonus_Buy_Available, Jackpot
)
SELECT DISTINCT
    GameID, Game, Game_Type, Game_Category, Release_Year,
    Languages, Mobile_Compatible, Free_Spins_Feature,
    Bonus_Buy_Available, Jackpot
FROM CasinoGames;

--2. Schema for DimCasino
CREATE TABLE DimCasino (
    CasinoID INT IDENTITY(1,1) PRIMARY KEY,  -- surrogate key
    Casino NVARCHAR(200)                     -- natural key from CasinoGames
    -- Optional: add attributes if available in source later
    -- Casino_Type NVARCHAR(100),            -- e.g., Online, Land-based
    -- Casino_Status NVARCHAR(50)            -- e.g., Active, Inactive
);

INSERT INTO DimCasino (Casino)
SELECT DISTINCT Casino
FROM CasinoGames;

--3 Schema for DimProvider
CREATE TABLE DimProvider (
    ProviderID INT IDENTITY(1,1) PRIMARY KEY,  -- surrogate key
    Provider NVARCHAR(200)                     -- natural key from CasinoGames
    -- Optional: add attributes later if available
    -- Headquarters NVARCHAR(200),
    -- FoundedYear INT,
    -- Provider_Status NVARCHAR(50)            -- e.g., Active, Inactive
);

INSERT INTO DimProvider (Provider)
SELECT DISTINCT Provider
FROM CasinoGames;

--4 Schema for DimCurrency
CREATE TABLE DimCurrency (
    CurrencyID INT IDENTITY(1,1) PRIMARY KEY,  -- surrogate key
    Currency NVARCHAR(50)                      -- natural key from CasinoGames
    -- Optional: add attributes later if available
    -- CurrencySymbol NVARCHAR(10),
    -- CurrencyName NVARCHAR(100),
    -- IsActive BIT
);
INSERT INTO DimCurrency (Currency)
SELECT DISTINCT Currency
FROM CasinoGames;

--Schema for DimVolatility
CREATE TABLE DimVolatility (
    VolatilityID INT IDENTITY(1,1) PRIMARY KEY,  -- surrogate key
    Volatility NVARCHAR(50)                      -- natural key from CasinoGames
    -- Optional: add attributes later if needed
    -- VolatilityScore INT,                      -- numeric scale (e.g., 1–5)
    -- VolatilityDescription NVARCHAR(200)       -- e.g., "High risk, high reward"
);

INSERT INTO DimVolatility (Volatility)
SELECT DISTINCT Volatility
FROM CasinoGames;

--Schema for DimDate
CREATE TABLE DimDate (
    DateID INT IDENTITY(1,1) PRIMARY KEY,   -- surrogate key
    DateValue DATE,                         -- actual date from CasinoGames (Last_Updated)
    Year INT,
    Month INT,
    Day INT,
    Quarter INT,
    DayOfWeek NVARCHAR(20)
);

INSERT INTO DimDate (DateValue, Year, Month, Day, Quarter, DayOfWeek)
SELECT DISTINCT 
    Last_Updated,
    YEAR(Last_Updated),
    MONTH(Last_Updated),
    DAY(Last_Updated),
    DATEPART(QUARTER, Last_Updated),
    DATENAME(WEEKDAY, Last_Updated)
FROM CasinoGames;

--Schema for DimRegulation
CREATE TABLE DimRegulation (
    RegulationID INT IDENTITY(1,1) PRIMARY KEY,   -- surrogate key
    License_Jurisdiction NVARCHAR(200)            -- natural key from CasinoGames
    -- Optional: add attributes later if available
    -- Regulator NVARCHAR(200),                   -- e.g., Malta Gaming Authority
    -- RegulationStatus NVARCHAR(50),             -- e.g., Active, Suspended
    -- Country NVARCHAR(100)                      -- country of jurisdiction
);


INSERT INTO DimRegulation (License_Jurisdiction)
SELECT DISTINCT License_Jurisdiction
FROM CasinoGames;

--Schema for DimRegion
CREATE TABLE DimRegion (
    RegionID INT IDENTITY(1,1) PRIMARY KEY,   -- surrogate key
    Country_Availability NVARCHAR(200)        -- natural key from CasinoGames
    -- Optional: add attributes later if available
    -- Continent NVARCHAR(100),               -- e.g., Europe, Africa
    -- RegionGroup NVARCHAR(100),             -- e.g., EU, LATAM
    -- IsActive BIT                           -- flag for current availability
);

INSERT INTO DimRegion (Country_Availability)
SELECT DISTINCT Country_Availability
FROM CasinoGames;

--Schema for DimLanguage
CREATE TABLE DimLanguage (
    LanguageID INT IDENTITY(1,1) PRIMARY KEY,   -- surrogate key
    Language NVARCHAR(100)                      -- natural key from CasinoGames
    -- Optional: add attributes later if available
    -- ISOCode NVARCHAR(10),                    -- e.g., EN, FR, ES
    -- Region NVARCHAR(100),                    -- e.g., Europe, Africa
    -- IsActive BIT                             -- flag for current support
);

INSERT INTO DimLanguage (Language)
SELECT DISTINCT Languages
FROM CasinoGames;

--Schema for FactCasinoGames
CREATE TABLE FactCasinoGames (
    FactID INT IDENTITY(1,1) PRIMARY KEY,   -- surrogate key for fact table
    
    -- Foreign Keys to Dimensions
    GameID INT NOT NULL,
    CasinoID INT NOT NULL,
    ProviderID INT NOT NULL,
    CurrencyID INT NOT NULL,
    VolatilityID INT NOT NULL,
    DateID INT NOT NULL,
    RegulationID INT NOT NULL,
    RegionID INT NOT NULL,
    LanguageID INT NOT NULL,
    
    -- Measures
    RTP DECIMAL(5,2),
    Max_Win DECIMAL(18,2),
    Min_Bet DECIMAL(18,2),
    Max_Multiplier BIGINT,
    WinToBetRatio DECIMAL(18,2),
    
    -- Derived Attributes
    RTP_Category NVARCHAR(50),
    VolatilityScore INT,
    GameAge INT,
    
    -- Flags / Attributes
    Jackpot NVARCHAR(50),
    Mobile_Compatible BIT,
    Free_Spins_Feature BIT,
    Bonus_Buy_Available BIT,
    
    -- Foreign Key Constraints
    FOREIGN KEY (GameID) REFERENCES DimGame(GameID),
    FOREIGN KEY (CasinoID) REFERENCES DimCasino(CasinoID),
    FOREIGN KEY (ProviderID) REFERENCES DimProvider(ProviderID),
    FOREIGN KEY (CurrencyID) REFERENCES DimCurrency(CurrencyID),
    FOREIGN KEY (VolatilityID) REFERENCES DimVolatility(VolatilityID),
    FOREIGN KEY (DateID) REFERENCES DimDate(DateID),
    FOREIGN KEY (RegulationID) REFERENCES DimRegulation(RegulationID),
    FOREIGN KEY (RegionID) REFERENCES DimRegion(RegionID),
    FOREIGN KEY (LanguageID) REFERENCES DimLanguage(LanguageID)
);

INSERT INTO FactCasinoGames (
    GameID, CasinoID, ProviderID, CurrencyID, VolatilityID, DateID,
    RegulationID, RegionID, LanguageID,
    RTP, Max_Win, Min_Bet, Max_Multiplier,
    WinToBetRatio, RTP_Category, VolatilityScore, GameAge,
    Jackpot, Mobile_Compatible, Free_Spins_Feature, Bonus_Buy_Available
)
SELECT 
    dg.GameID,
    dc.CasinoID,
    dp.ProviderID,
    dcur.CurrencyID,
    dv.VolatilityID,
    dd.DateID,
    dr.RegulationID,
    dreg.RegionID,
    dl.LanguageID,

    cg.RTP,
    cg.Max_Win,
    TRY_CAST(cg.Min_Bet AS DECIMAL(18,2)),
    cg.Max_Multiplier,

    -- Derived Measures
    CASE WHEN TRY_CAST(cg.Min_Bet AS DECIMAL(18,2)) > 0 
         THEN cg.Max_Win / TRY_CAST(cg.Min_Bet AS DECIMAL(18,2)) ELSE 0 END AS WinToBetRatio,

    CASE WHEN cg.RTP >= 98 THEN 'Very High'
         WHEN cg.RTP >= 95 THEN 'High'
         WHEN cg.RTP >= 90 THEN 'Medium'
         ELSE 'Low' END AS RTP_Category,

    CASE WHEN cg.Volatility = 'Very High' THEN 5
         WHEN cg.Volatility = 'High' THEN 4
         WHEN cg.Volatility = 'Medium' THEN 3
         WHEN cg.Volatility = 'Low' THEN 2
         ELSE 1 END AS VolatilityScore,

    DATEDIFF(YEAR, cg.Release_Year, YEAR(GETDATE())) AS GameAge,

    cg.Jackpot,
    cg.Mobile_Compatible,
    cg.Free_Spins_Feature,
    cg.Bonus_Buy_Available
FROM CasinoGames cg
INNER JOIN DimGame dg ON cg.GameID = dg.GameID
INNER JOIN DimCasino dc ON cg.Casino = dc.Casino
INNER JOIN DimProvider dp ON cg.Provider = dp.Provider
INNER JOIN DimCurrency dcur ON cg.Currency = dcur.Currency
INNER JOIN DimVolatility dv ON cg.Volatility = dv.Volatility
INNER JOIN DimDate dd ON cg.Last_Updated = dd.DateValue
INNER JOIN DimRegulation dr ON cg.License_Jurisdiction = dr.License_Jurisdiction
INNER JOIN DimRegion dreg ON cg.Country_Availability = dreg.Country_Availability
INNER JOIN DimLanguage dl ON cg.Languages = dl.Language;

--Verify the Star Schema
--Row counts
SELECT COUNT(*) FROM DimGame;
SELECT COUNT(*) FROM DimCasino;
SELECT COUNT(*) FROM FactCasinoGames;

--Referential integrity
SELECT f.*
FROM FactCasinoGames f
LEFT JOIN DimGame g ON f.GameID = g.GameID
WHERE g.GameID IS NULL;

--Business rules
SELECT * FROM FactCasinoGames WHERE RTP < 0 OR RTP > 100;
SELECT * FROM FactCasinoGames WHERE Min_Bet <= 0;


--List All Star Schema Tables
-- Show all tables in your CasinoDB that match your star schema
SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
  AND TABLE_NAME IN (
    'DimGame',
    'DimCasino',
    'DimProvider',
    'DimCurrency',
    'DimVolatility',
    'DimDate',
    'DimRegulation',
    'DimRegion',
    'DimLanguage',
    'FactCasinoGames'
  );

  SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'DimDate';

SELECT *
FROM DimDate;

SELECT *
FROM DimLanguage;

SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'DimLanguage';

SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'FactCasinoGames';


SELECT COUNT(*) FROM FactCasinoGames;

SELECT TOP 20 *
FROM FactCasinoGames
ORDER BY FactID DESC;

SELECT f.FactID, g.Game, c.Casino, l.Language, d.Year
FROM FactCasinoGames f
JOIN DimGame g ON f.GameID = g.GameID
JOIN DimCasino c ON f.CasinoID = c.CasinoID
JOIN DimLanguage l ON f.LanguageID = l.LanguageID
JOIN DimDate d ON f.DateID = d.DateID;

--WinToBetRatio:
UPDATE FactCasinoGames
SET WinToBetRatio = CASE 
    WHEN Min_Bet > 0 THEN Max_Win / Min_Bet 
    ELSE NULL END;

--GameAge (based on release year):
UPDATE f
SET GameAge = YEAR(GETDATE()) - d.Year
FROM FactCasinoGames f
JOIN DimDate d ON f.DateID = d.DateID;

--RTP_Category (example thresholds):
UPDATE FactCasinoGames
SET RTP_Category = CASE 
    WHEN RTP >= 97 THEN 'High'
    WHEN RTP BETWEEN 94 AND 96 THEN 'Medium'
    ELSE 'Low' END;

--Try a simple aggregation
SELECT ProviderID, AVG(RTP) AS AvgRTP, COUNT(*) AS GameCount
FROM FactCasinoGames
GROUP BY ProviderID;


--Verification Recap
--Schema integrity → dimensions and fact table exist.
--Data quality checks → no invalid RTP or Min_Bet values.
--Referential integrity → fact table rows correctly link to dimension surrogate keys.
--the star schema is clean and valid.