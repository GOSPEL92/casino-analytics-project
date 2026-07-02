--Data Profiling
--Script: 03_Data_Profiling.sql

--Purpose: Runs queries for data quality checks (null counts, duplicates, distributions
--Output: Save profiling results into a Profiling_Report table.

--Add a Surrogate Key (GameID) After Ingestion
ALTER TABLE CasinoGames
ADD GameID INT IDENTITY(1,1) PRIMARY KEY;

-- 1. Row count
SELECT COUNT(*) AS TotalRows FROM CasinoGames;

-- 2. Sample rows
SELECT TOP 20 * FROM CasinoGames;

-- 3. Distinct values for categorical columns
SELECT DISTINCT Volatility FROM CasinoGames;
SELECT DISTINCT Currency FROM CasinoGames;
SELECT DISTINCT Game_Type FROM CasinoGames;
SELECT DISTINCT Game_Category FROM CasinoGames;
SELECT DISTINCT License_Jurisdiction FROM CasinoGames;

-- 4. Range checks for numeric-like columns (still text for now)
SELECT MIN(RTP), MAX(RTP) FROM CasinoGames;
SELECT MIN(Min_Bet), MAX(Min_Bet) FROM CasinoGames;
SELECT MIN(Max_Win), MAX(Max_Win) FROM CasinoGames;
SELECT MIN(Release_Year), MAX(Release_Year) FROM CasinoGames;

-- 5. Missing or invalid values
SELECT * FROM CasinoGames WHERE RTP IS NULL OR RTP = 'N/A';
SELECT * FROM CasinoGames WHERE Release_Year IS NULL OR ISNUMERIC(Release_Year) = 0;
SELECT * FROM CasinoGames WHERE Currency IS NULL OR Currency = '';

--This dataset might not literally use NULL or N/A — it could use other placeholders like "NA", "None", "0", or even spaces.
                             --How to Dig Deeper
--Tried these variations to catch hidden issues:
-- Check for blank strings (including spaces)
SELECT * 
FROM CasinoGames
WHERE LTRIM(RTRIM(RTP)) = '';

-- Check for non-numeric values in Release_Year
SELECT DISTINCT Release_Year
FROM CasinoGames
WHERE ISNUMERIC(Release_Year) = 0;

-- Check Currency values longer than expected
SELECT DISTINCT Currency, LEN(Currency) AS Length
FROM CasinoGames
ORDER BY Length DESC;

-- Check Last_Updated values that don’t look like dates
SELECT DISTINCT Last_Updated
FROM CasinoGames
WHERE TRY_CONVERT(DATE, Last_Updated) IS NULL;

                         --Full Anomaly‑Detection Script

-- 1. Check for blank or whitespace-only values across key columns
SELECT * 
FROM CasinoGames
WHERE LTRIM(RTRIM(Casino)) = ''
   OR LTRIM(RTRIM(Game)) = ''
   OR LTRIM(RTRIM(Provider)) = ''
   OR LTRIM(RTRIM(Currency)) = '';

-- 2. Detect non-numeric values in numeric-like columns
SELECT DISTINCT RTP
FROM CasinoGames
WHERE TRY_CONVERT(FLOAT, RTP) IS NULL;

SELECT DISTINCT Min_Bet
FROM CasinoGames
WHERE TRY_CONVERT(DECIMAL(10,2), Min_Bet) IS NULL;

SELECT DISTINCT Max_Win
FROM CasinoGames
WHERE TRY_CONVERT(DECIMAL(15,2), Max_Win) IS NULL;

SELECT DISTINCT Release_Year
FROM CasinoGames
WHERE TRY_CONVERT(INT, Release_Year) IS NULL;

SELECT DISTINCT Max_Multiplier
FROM CasinoGames
WHERE TRY_CONVERT(INT, Max_Multiplier) IS NULL;

-- 3. Detect invalid dates in Last_Updated
SELECT DISTINCT Last_Updated
FROM CasinoGames
WHERE TRY_CONVERT(DATE, Last_Updated) IS NULL;

-- 4. Currency anomalies: unexpected codes or long strings
SELECT DISTINCT Currency, LEN(Currency) AS Length
FROM CasinoGames
ORDER BY Length DESC;

-- 5. Volatility anomalies: unexpected categories
SELECT DISTINCT Volatility
FROM CasinoGames
WHERE Volatility NOT IN ('High','Medium','Low');

-- 6. Mobile compatibility anomalies
SELECT DISTINCT Mobile_Compatible
FROM CasinoGames
WHERE Mobile_Compatible NOT IN ('Yes','No','True','False','1','0');


--What This Script Does
--Blanks check → catches empty strings or whitespace.

--Non‑numeric checks → finds values like “N/A”, “None”, or text in numeric columns.

--Invalid dates → highlights rows where Last_Updated isn’t a valid date.

--Currency anomalies → shows unusual codes or overly long strings.

--Volatility anomalies → ensures only High/Medium/Low are used.

--Mobile compatibility anomalies → checks for inconsistent Yes/No/True/False values.

--                                      Anomaly Findings & Solutions
--1. MaxMultiplier
  --.Finding: One row had NULL in the MaxMultiplier column.
  --. Problem: This breaks numeric analysis if left unhandled.
  --.Solution:
  --.Option A: Leave as NULL to indicate “missing/unknown.”
  --.Option B: Replace with a default (like 1) if business logic requires every game to have a multiplier.
  UPDATE CasinoGames
SET Max_Multiplier = 1
WHERE Max_Multiplier IS NULL;
--.In our case, we flagged it and chose to either keep as NULL or replace with 1 depending on analysis needs.

--2. Currency
--Finding: Some rows contained multiple currencies in one field, e.g. CAD|BRL|DKK|CHF|GBP|USD|NOK|SEK
-- Problem: Pipe‑separated values make it impossible to filter or group by currency properly.
--. Solution: Normalize into a separate table using STRING_SPLIT:
CREATE TABLE GameCurrencies (
    GameID INT,
    Currency NVARCHAR(10)
);

INSERT INTO GameCurrencies (GameID, Currency)
SELECT g.GameID, value
FROM CasinoGames g
CROSS APPLY STRING_SPLIT(g.Currency, '|');

--Now each game has multiple rows in GameCurrencies, one per currency, making analysis clean.


-- Next Clean Numeric Columns
-- Convert text columns into proper numeric types after handling anomalies:
-- Fix RTP
UPDATE CasinoGames
SET RTP = NULL
WHERE TRY_CONVERT(FLOAT, RTP) IS NULL;

ALTER TABLE CasinoGames
ALTER COLUMN RTP FLOAT;

-- Fix Release_Year
UPDATE CasinoGames
SET Release_Year = NULL
WHERE TRY_CONVERT(INT, Release_Year) IS NULL;

ALTER TABLE CasinoGames
ALTER COLUMN Release_Year INT;

-- Fix MaxMultiplier
UPDATE CasinoGames
SET Max_Multiplier = NULL
WHERE TRY_CONVERT(INT, Max_Multiplier) IS NULL;

ALTER TABLE CasinoGames
ALTER COLUMN Max_Multiplier INT;
--This  convert the column into a proper integer type. After that,i  analyze it:

SELECT COUNT(*) AS TotalGames,
       COUNT(Max_Multiplier) AS WithMultiplier,
       COUNT(*) - COUNT(Max_Multiplier) AS MissingMultiplier,
       AVG(Max_Multiplier) AS AvgMultiplier
FROM CasinoGames;
--this hit errow , so i will another method

--How to Fix It
--Use a larger numeric type:
ALTER TABLE CasinoGames
ALTER COLUMN Max_Multiplier BIGINT;
--BIGINT can hold values up to 9 quintillion — plenty of room.


--Next Step: Profile the Column
--After conversion, check the distribution:
SELECT MIN(Max_Multiplier) AS MinMultiplier,
       MAX(Max_Multiplier) AS MaxMultiplier,
       AVG(Max_Multiplier) AS AvgMultiplier,
       COUNT(*) AS TotalRows,
       COUNT(Max_Multiplier) AS NonNullRows
FROM CasinoGames;

 --interpretation of the distribution
-- MinMultiplier = 10 → the smallest multiplier in your dataset is 10.

-- MaxMultiplier = 50000 → the largest multiplier is 50,000 (well within BIGINT range).

--AvgMultiplier = 6139 → the average multiplier across all non‑NULL rows is ~6,139.

--TotalRows = 1,200,000 → your dataset has 1.2 million rows.

-- NonNullRows = 986,186 → about 986k rows have valid multiplier values, meaning ~213k rows were set to NULL during cleaning.

-- Distribution of multipliers
SELECT Max_Multiplier, COUNT(*) AS CountGames
FROM CasinoGames
WHERE Max_Multiplier IS NOT NULL
GROUP BY Max_Multiplier
ORDER BY CountGames DESC;

--checking for NULL values in Max_Win 
-- Count how many rows have NULL in Max_Win
SELECT COUNT(*) AS NullMaxWin
FROM CasinoGames
WHERE Max_Win IS NULL;

-- Compare with total rows
SELECT COUNT(*) AS TotalRows,
       COUNT(Max_Win) AS NonNullRows,
       COUNT(*) - COUNT(Max_Win) AS NullRows
FROM CasinoGames;

--check data quality — are those values numeric, within realistic ranges, and consistent?
--Next Checks for Max_Win
--1. Confirm Numeric Validity
SELECT DISTINCT Max_Win
FROM CasinoGames
WHERE TRY_CONVERT(DECIMAL(15,2), Max_Win) IS NULL;
-- This will show if any rows contain text placeholders (like “N/A”, “None”, “-”) instead of numbers.


SELECT MIN(TRY_CONVERT(DECIMAL(15,2), Max_Win)) AS MinMaxWin,
       MAX(TRY_CONVERT(DECIMAL(15,2), Max_Win)) AS MaxMaxWin,
       AVG(TRY_CONVERT(DECIMAL(15,2), Max_Win)) AS AvgMaxWin
FROM CasinoGames;
--This tells you the smallest, largest, and average max win values.

--Distribution Check
SELECT TOP 20 Max_Win, COUNT(*) AS CountGames
FROM CasinoGames
GROUP BY Max_Win
ORDER BY CountGames DESC;

--Convert Max_Win to Numeric
--Since it represents a monetary‑like value (maximum win), the best choice is DECIMAL(15,2):
ALTER TABLE CasinoGames
ALTER COLUMN Max_Win DECIMAL(15,2);

--Profiling Max_Win After Conversion
SELECT MIN(Max_Win) AS MinMaxWin,
       MAX(Max_Win) AS MaxMaxWin,
       AVG(Max_Win) AS AvgMaxWin,
       COUNT(*) AS TotalRows
FROM CasinoGames;

--By Provider:

--By Volatility:
SELECT Volatility, AVG(Max_Win) AS AvgMaxWin
FROM CasinoGames
GROUP BY Volatility;

--By Currency (using your normalized table):
SELECT c.Currency, AVG(g.Max_Win) AS AvgMaxWin
FROM CasinoGames g
JOIN GameCurrencies c ON g.GameID = c.GameID
GROUP BY c.Currency
ORDER BY AvgMaxWin DESC;


--Check for Non‑Numeric Values for RTP, This will show if any rows contain text placeholders like "N/A", "None", or blanks instead of numbers.
SELECT DISTINCT RTP
FROM CasinoGames
WHERE TRY_CONVERT(DECIMAL(5,2), RTP) IS NULL;


--Range Profiling for RTP , This gives you the minimum, maximum, average RTP, and how many rows are valid vs missing.
SELECT MIN(TRY_CONVERT(DECIMAL(5,2), RTP)) AS MinRTP,
       MAX(TRY_CONVERT(DECIMAL(5,2), RTP)) AS MaxRTP,
       AVG(TRY_CONVERT(DECIMAL(5,2), RTP)) AS AvgRTP,
       COUNT(*) AS TotalRows,
       COUNT(TRY_CONVERT(DECIMAL(5,2), RTP)) AS NonNullRows
FROM CasinoGames;

--Distribution Check for RTP, This shows the most common RTP values (e.g., 95.00%, 96.50%, etc.).
SELECT RTP, COUNT(*) AS CountGames
FROM CasinoGames
WHERE TRY_CONVERT(DECIMAL(5,2), RTP) IS NOT NULL
GROUP BY RTP
ORDER BY CountGames DESC;


                    -- Data Cleaning & Conversion
-- 1. RTP → DECIMAL
UPDATE CasinoGames
SET RTP = NULL
WHERE TRY_CONVERT(DECIMAL(5,2), RTP) IS NULL;

ALTER TABLE CasinoGames
ALTER COLUMN RTP DECIMAL(5,2);

-- 2. Max_Win → DECIMAL
UPDATE CasinoGames
SET Max_Win = NULL
WHERE TRY_CONVERT(DECIMAL(15,2), Max_Win) IS NULL;

ALTER TABLE CasinoGames
ALTER COLUMN Max_Win DECIMAL(15,2);

-- 3. Release_Year → INT
UPDATE CasinoGames
SET Release_Year = NULL
WHERE TRY_CONVERT(INT, Release_Year) IS NULL;

ALTER TABLE CasinoGames
ALTER COLUMN Release_Year INT;

-- 4. Last_Updated → DATE
UPDATE CasinoGames
SET Last_Updated = NULL
WHERE TRY_CONVERT(DATE, Last_Updated) IS NULL;

ALTER TABLE CasinoGames
ALTER COLUMN Last_Updated DATE;

-- 5. Max_Multiplier → BIGINT (already cleaned earlier)
UPDATE CasinoGames
SET Max_Multiplier = NULL
WHERE TRY_CONVERT(BIGINT, Max_Multiplier) IS NULL;

ALTER TABLE CasinoGames
ALTER COLUMN Max_Multiplier BIGINT;

-- 6. Boolean Columns → BIT
UPDATE CasinoGames
SET Mobile_Compatible = CASE 
    WHEN Mobile_Compatible IN ('Yes','True','1') THEN '1'
    WHEN Mobile_Compatible IN ('No','False','0') THEN '0'
    ELSE NULL END;

ALTER TABLE CasinoGames
ALTER COLUMN Mobile_Compatible BIT;

UPDATE CasinoGames
SET Free_Spins_Feature = CASE 
    WHEN Free_Spins_Feature IN ('Yes','True','1') THEN '1'
    WHEN Free_Spins_Feature IN ('No','False','0') THEN '0'
    ELSE NULL END;

ALTER TABLE CasinoGames
ALTER COLUMN Free_Spins_Feature BIT;

UPDATE CasinoGames
SET Bonus_Buy_Available = CASE 
    WHEN Bonus_Buy_Available IN ('Yes','True','1') THEN '1'
    WHEN Bonus_Buy_Available IN ('No','False','0') THEN '0'
    ELSE NULL END;

ALTER TABLE CasinoGames
ALTER COLUMN Bonus_Buy_Available BIT;


--What This Script Does
-- Cleans invalid values → replaces with NULL.

--Converts text columns into proper numeric/date/bit types.

--Ensures consistency across categorical values.

--Leaves you with a fully structured relational table ready for analysis.