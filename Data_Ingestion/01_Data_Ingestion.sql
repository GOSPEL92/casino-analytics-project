--1. Database Setup
--Script: 01_Create_Database.sql

--Purpose: Creates the CasinoAnalytics database and sets up initial schema.


--Create a Database
CREATE DATABASE CasinoAnalytics;
GO
--Create Staging Table
DROP TABLE IF EXISTS CasinoGames;

CREATE TABLE CasinoGames (
    Casino NVARCHAR(200),
    Game NVARCHAR(200),
    Provider NVARCHAR(200),
    RTP NVARCHAR(50),
    Volatility NVARCHAR(50),
    Jackpot NVARCHAR(50),
    Country_Availability NVARCHAR(200),
    Min_Bet NVARCHAR(50),
    Max_Win NVARCHAR(50),
    Game_Type NVARCHAR(100),
    Game_Category NVARCHAR(100),
    License_Jurisdiction NVARCHAR(200),
    Release_Year NVARCHAR(50),
    Currency NVARCHAR(50),
    Mobile_Compatible NVARCHAR(50),
    Free_Spins_Feature NVARCHAR(50),
    Bonus_Buy_Available NVARCHAR(50),
    Max_Multiplier NVARCHAR(50),
    Languages NVARCHAR(200),
    Last_Updated NVARCHAR(50)
);


--2. Data Ingestion
--Script: 02_Data_Ingestion.sql
--Purpose: Loads raw CSV data into staging tables.
-- This is a CSV Casinodataset collected from Kaggle for this Project prtfolio

--Bulk Insert the CSV
BULK INSERT CasinoGames
FROM 'C:\Users\HP\Downloads\CasionProject\online_casino_games_dataset_v2.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);

--Verify
SELECT TOP 10 * FROM CasinoGames;
