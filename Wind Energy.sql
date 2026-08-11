SELECT *
FROM Wind

SELECT windspeed_100m
FROM Wind
---------------------------------------------------------------------------------------
/* AVG Power & Wind-Speed*/
SELECT
    City,
    AVG(Power) AS Average_Power_Output,
    AVG(windspeed_100m) AS Avg_Wind_Speed_100m,
    MAX(windspeed_100m) AS Max_Wind_Speed_100m
FROM
    Wind
GROUP BY
    City
ORDER BY
    Average_Power_Output DESC;
----------------------------------------------------------
/* Prouduction Energy By Hour */
SELECT
    DATEPART(HOUR, Time) AS Hour_Of_Day,
    AVG(Power) AS Average_Power
FROM
    Wind
WHERE
    City = 'berlin'
GROUP BY
    DATEPART(HOUR, Time) 
ORDER BY
    Hour_Of_Day;
-----------------------------------------------------------
/*Top city by year*/

WITH PreparedData AS
(
    SELECT
        City,
        Power,
        TRY_CONVERT(DATE, Date, 101) AS Converted_Date,
        TRY_CAST(Time AS TIME) AS Converted_Time
    FROM Wind),
CombinedData AS
(
    SELECT
        City,
        Power,
        CAST(Converted_Date AS DATETIME) + CAST(Converted_Time AS DATETIME) AS EventTime
    FROM
        PreparedData
    WHERE
        Converted_Date IS NOT NULL AND Converted_Time IS NOT NULL),

YearlyProduction AS
(
    SELECT
        City,
        YEAR(EventTime) AS Production_Year,
        SUM(Power) AS Total_Yearly_Power
    FROM
        CombinedData
    GROUP BY
        City, YEAR(EventTime)
),
RankedYearly AS
(
    SELECT
        City,
        Production_Year,
        Total_Yearly_Power,
        RANK() OVER(PARTITION BY Production_Year ORDER BY Total_Yearly_Power DESC) AS City_Rank
    FROM
        YearlyProduction)
SELECT
    Production_Year,
    City AS Top_City_Of_The_Year,
    Total_Yearly_Power
FROM
    RankedYearly
WHERE
    City_Rank = 1         
ORDER BY
    Production_Year;
-------------------------------------------------------------------------------
/*TOP Cities by Month*/
WITH PreparedData AS
(
    SELECT
        City,
        Power,
        TRY_CONVERT(DATE, Date, 101) AS Converted_Date,
        TRY_CAST(Time AS TIME) AS Converted_Time
    FROM
        Wind),
CombinedData AS(
    SELECT
        City,
        Power,
        CAST(Converted_Date AS DATETIME) + CAST(Converted_Time AS DATETIME) AS EventTime
    FROM
        PreparedData
    WHERE
        Converted_Date IS NOT NULL AND Converted_Time IS NOT NULL),
MonthlyProduction AS
(
    SELECT
        City,
        YEAR(EventTime) AS Production_Year,
        MONTH(EventTime) AS Production_Month,
        FORMAT(EventTime, 'yyyy-MM') AS Year_Month,
        SUM(Power) AS Total_Monthly_Power
    FROM
        CombinedData
    GROUP BY
        City, YEAR(EventTime), MONTH(EventTime), FORMAT(EventTime, 'yyyy-MM')),
RankedMonthly AS
(
    SELECT
        City,
        Year_Month,
        Total_Monthly_Power,
        RANK() OVER(PARTITION BY Year_Month ORDER BY Total_Monthly_Power DESC) AS City_Rank
    FROM
        MonthlyProduction)
SELECT
    Year_Month,
    City AS Top_City_Of_The_Month,
    Total_Monthly_Power
FROM
    RankedMonthly
WHERE
    City_Rank = 1
ORDER BY
    Year_Month DESC;
-------------------------------------------------------------------------------
/*City per Day */
WITH PreparedData AS
(
    SELECT
        City,
        Power,
        TRY_CONVERT(DATE, Date, 101) AS Production_Day
    FROM
        Wind
)
SELECT
    City,
    Production_Day,
    
    SUM(Power) AS Total_Daily_Power
FROM
    PreparedData
WHERE
    City = 'Berlin'   
    AND Production_Day IS NOT NULL 
GROUP BY
    City, Production_Day
ORDER BY
    Production_Day ASC;
---------------------------------------------------------------------------
/* Using CTE To Jumping Between Energy*/

WITH CombinedData AS
(
    SELECT
        City,        
        TRY_CAST(Date AS DATETIME) + TRY_CAST(Time AS DATETIME) AS EventTime,
        Power
    FROM
        Wind
   
    WHERE
        TRY_CONVERT(DATE, Date, 101) IS NOT NULL
        AND TRY_CAST(Time AS TIME) IS NOT NULL),
HourlyPowerChanges AS(
    SELECT
        City,
        EventTime,
        Power AS Current_Hour_Power,
        LAG(Power, 1, 0) OVER (PARTITION BY City ORDER BY EventTime) AS Previous_Hour_Power
    FROM
        CombinedData)
SELECT TOP 10
    City,
    EventTime AS Ramp_Up_Time_Finished,
    Previous_Hour_Power,
    Current_Hour_Power,
    (Current_Hour_Power - Previous_Hour_Power) AS Power_Increase_In_One_Hour
FROM
    HourlyPowerChanges
WHERE
    Current_Hour_Power > Previous_Hour_Power 
    AND Previous_Hour_Power != 0 
ORDER BY
    Power_Increase_In_One_Hour DESC; 
-----------------------------------------------------------------------------------------
WITH GustFactorData AS
(
    SELECT
        City,
        Power,
        windspeed_100m,
        windspeed_10m,
        windgusts_10m,
        (windgusts_10m / NULLIF(windspeed_10m, 0)) AS Gust_Factor
    FROM
        Wind
    WHERE
        windspeed_10m > 1 
        AND windgusts_10m > 0),

CategorizedGusts AS
(
    SELECT
        City,
        Power,
        windspeed_100m,
        Gust_Factor,
        
        
        CASE
            WHEN Gust_Factor < 1.3 THEN '1. Smooth'
            WHEN Gust_Factor < 1.6 THEN '2. Gusty'
            WHEN Gust_Factor < 2.0 THEN '3. Stormy'
            WHEN Gust_Factor >= 2.0 THEN '4. Extreme'
            ELSE 'N/A'
        END AS Gust_Category
    FROM
        GustFactorData
    WHERE
        Gust_Factor IS NOT NULL )
SELECT
    City,
    Gust_Category,
    
    AVG(Power) AS Average_Power_Output,
    AVG(windspeed_100m) AS Avg_Turbine_Wind_Speed,    
    MIN(Gust_Factor) AS Min_Gust_Factor_In_Category,
    MAX(Gust_Factor) AS Max_Gust_Factor_In_Category,
    COUNT(*) AS Total_Hours_In_Category
FROM
    CategorizedGusts
GROUP BY
    City, Gust_Category
ORDER BY
    City,
    Gust_Category;
----------------------------------------------------------------------------------------
/* Wind Stability Analysis */

WITH CombinedData AS
(
    SELECT
        City,
        Power,
        winddirection_100m,
        TRY_CAST(Date AS DATETIME) + TRY_CAST(Time AS DATETIME) AS EventTime
    FROM
        Wind
    WHERE
        TRY_CONVERT(DATE, Date, 101) IS NOT NULL
        AND TRY_CAST(Time AS TIME) IS NOT NULL),
DirectionalChanges AS
(
    SELECT
        City,
        Power,
        EventTime,
        winddirection_100m AS Current_Direction,
        
        LAG(winddirection_100m, 1, winddirection_100m) OVER (PARTITION BY City ORDER BY EventTime) AS Previous_Direction,

        (winddirection_100m - LAG(winddirection_100m, 1, winddirection_100m) OVER (PARTITION BY City ORDER BY EventTime)) AS Raw_Difference
    FROM
        CombinedData
),
CorrectedAndCategorized AS
(
    SELECT
        City,
        Power,
        ABS(
            CASE
                WHEN Raw_Difference > 180  THEN Raw_Difference - 360
                WHEN Raw_Difference < -180 THEN Raw_Difference + 360
                ELSE Raw_Difference
            END
        ) AS Hourly_Direction_Change_Degrees,
        
        CASE
            WHEN Current_Direction > 337.5 OR Current_Direction <= 22.5 THEN 'North'
            WHEN Current_Direction > 22.5 AND Current_Direction <= 67.5 THEN 'Northeast'
            WHEN Current_Direction > 67.5 AND Current_Direction <= 112.5 THEN 'East'
            WHEN Current_Direction > 112.5 AND Current_Direction <= 157.5 THEN 'Southeast'
            WHEN Current_Direction > 157.5 AND Current_Direction <= 202.5 THEN 'South'
            WHEN Current_Direction > 202.5 AND Current_Direction <= 247.5 THEN 'Southwest'
            WHEN Current_Direction > 247.5 AND Current_Direction <= 292.5 THEN 'West'
            WHEN Current_Direction > 292.5 AND Current_Direction <= 337.5 THEN 'Northwest' 
            ELSE 'Unknown'
        END AS Wind_Direction_Sector
    FROM
        DirectionalChanges
    WHERE
        Raw_Difference != 0
)

SELECT
    City,
    Wind_Direction_Sector,
    
    AVG(Hourly_Direction_Change_Degrees) AS Avg_Direction_Change,
    
    AVG(Power) AS Average_Power,
    
    COUNT(*) AS Total_Hours
FROM
    CorrectedAndCategorized
GROUP BY
    City, Wind_Direction_Sector
ORDER BY
    City,
    Avg_Direction_Change ASC;
----------------------------------------------------------------------------------------------
/* Analysis Of the effect of humidity on stormy winds*/

WITH PreparedData AS
(
    SELECT
        City,
        Power,
        TRY_CAST(Date AS DATETIME) + TRY_CAST(Time AS DATETIME) AS EventTime,
        
    
        TRY_CAST(temperature_2m AS FLOAT) AS temperature_2m,
        TRY_CAST(relativehumidity_2m AS FLOAT) AS relativehumidity_2m,
        TRY_CAST(dewpoint_2m AS FLOAT) AS dewpoint_2m,
        TRY_CAST(windspeed_10m AS FLOAT) AS windspeed_10m,
        TRY_CAST(windgusts_10m AS FLOAT) AS windgusts_10m
    FROM
        Wind
    WHERE
     
        TRY_CONVERT(DATE, Date, 101) IS NOT NULL
        AND TRY_CAST(Time AS TIME) IS NOT NULL
        AND TRY_CAST(windspeed_10m AS FLOAT) > 0
),
AtmosphericAnalysis AS
(
    SELECT
        City,
        Power,
        EventTime,
        windspeed_10m,
        windgusts_10m,

        CASE
            WHEN relativehumidity_2m > 90 AND (temperature_2m - dewpoint_2m) < 2
                THEN '1. Fog/High Mist'
            WHEN relativehumidity_2m > 75
                THEN '2. Humid'
            WHEN relativehumidity_2m < 50
                THEN '3. Dry'
            ELSE
                '4. Moderate'
        END AS Atmosphere_Category
    FROM
        PreparedData ),
CombinedFactors AS(
    SELECT
        City,
        Power,
        Atmosphere_Category,
        (windgusts_10m / windspeed_10m) AS Gust_Factor,

        CASE
            WHEN (windgusts_10m / windspeed_10m) < 1.6 THEN 'Smooth/Steady Wind '
            ELSE 'Gusty/Turbulent Wind'
        END AS Wind_Type
    FROM
        AtmosphericAnalysis
    WHERE
        windspeed_10m != 0
)
SELECT
    City,
    Atmosphere_Category AS 'Weather Condition',
    Wind_Type AS 'Wind Type',
    
    AVG(Power) AS Average_Power_Output,
    
    AVG(Gust_Factor) AS Average_Gust_Factor_Value,
    COUNT(*) AS Total_Hours_Observed
FROM
    CombinedFactors
GROUP BY
    City,
    Atmosphere_Category,
    Wind_Type
ORDER BY
    City,
    Atmosphere_Category,
    Wind_Type;
----------------------------------------------------------------------------------------------
/* Analysis Of energy production using the difference between wind speeds */
WITH WindShearMetrics AS
(
    SELECT
        City,
        Power,
        windspeed_100m,
        windspeed_10m,
        (windspeed_100m - windspeed_10m) AS Shear_Difference_ms 
    FROM
        Wind
    WHERE
        Power > 0 
        AND windspeed_10m > 0
),
CategorizedShear AS
(
    SELECT
        City,
        Power,
        windspeed_100m,
        Shear_Difference_ms,
        
       
        CASE
          
            WHEN Shear_Difference_ms <= 3 THEN 'Low Shear (¬„‰/„ Ã«‰”)'
            
            WHEN Shear_Difference_ms > 3 AND Shear_Difference_ms <= 6 THEN 'Medium Shear („ Ê”ÿ «·≈ÃÂ«œ)'
            
            WHEN Shear_Difference_ms > 6 THEN 'High Shear (≈ÃÂ«œ ⁄«·Ì/Œÿ—)'
            
        END AS Shear_Stress_Level
    FROM
        WindShearMetrics
)
SELECT
    City,
    Shear_Stress_Level,
    
    AVG(Power) AS Average_Power_Output,
    
    AVG(windspeed_100m) AS Avg_WindSpeed_At_Turbine,
    
    AVG(Shear_Difference_ms) AS Avg_Shear_Difference,
    
    COUNT(*) AS Total_Hours_Observed
FROM
    CategorizedShear
WHERE
    Shear_Stress_Level IS NOT NULL 
GROUP BY
    City,
    Shear_Stress_Level
ORDER BY
    City,
    Shear_Stress_Level;
------------------------------------------------------------------------------------
/* Analysis Of the effect of humidity on energy effiency*/

WITH BinnedAnalysisData AS
(
    SELECT
        City,
        Power,
        windspeed_100m,
        relativehumidity_2m,
        FLOOR(windspeed_100m / 2.0) * 2 AS Wind_Speed_Bin_Start,
        
        CASE
            WHEN relativehumidity_2m < 50 THEN '(Dry - Lower Density)'
            WHEN relativehumidity_2m >= 50 AND relativehumidity_2m < 80 THEN 'Moderate'
            WHEN relativehumidity_2m >= 80 THEN '(Humid - Higher Density)'
            ELSE 'N/A'
        END AS Humidity_Category
    FROM
        Wind
    WHERE
        Power > 0 
        AND windspeed_100m > 3
        AND relativehumidity_2m IS NOT NULL
)
SELECT
    City,
    CAST(Wind_Speed_Bin_Start AS VARCHAR(10)) + ' - ' + 
    CAST(Wind_Speed_Bin_Start + 1.99 AS VARCHAR(10)) + ' m/s' AS Wind_Speed_Range,
    
    Humidity_Category,
    
    AVG(Power) AS Average_Power_Output,
    
    AVG(windspeed_100m) AS Actual_Avg_Wind_Speed,
  
    COUNT(*) AS Total_Hours_Observed
FROM
    BinnedAnalysisData
WHERE
    Wind_Speed_Bin_Start >= 6
GROUP BY
    City,
    Wind_Speed_Bin_Start,
    Humidity_Category
ORDER BY
    City,
    Wind_Speed_Bin_Start,
    Humidity_Category;
----------------------------------------------------------------------------------------------------------------------
/* Analysis of turbine efficiency at maximum speed */

WITH PerformanceMetrics AS
(
    SELECT
        City,
        Power,
        windspeed_100m,
        (Power / POWER(windspeed_100m, 3)) AS Efficiency_Index
    FROM
        Wind
    WHERE
        Power > 0 
        AND windspeed_100m > 3 )
, BinnedPerformance AS(
    SELECT
        City,
        Power,
        Efficiency_Index,
        FLOOR(windspeed_100m) AS Wind_Speed_Bin
    FROM
        PerformanceMetrics
    WHERE
        Efficiency_Index IS NOT NULL
        AND Efficiency_Index > 0),

RankedEfficiency AS(
    SELECT
        City,
        CAST(Wind_Speed_Bin AS VARCHAR(10)) + '.0 - ' + 
        CAST(Wind_Speed_Bin + 0.99 AS VARCHAR(10)) + ' m/s' AS Wind_Speed_Range,
        
        AVG(Efficiency_Index) AS Avg_Efficiency_Index,
        AVG(Power) AS Avg_Power_In_Bin,
        COUNT(*) AS Total_Hours_In_Bin,
        RANK() OVER(PARTITION BY City ORDER BY AVG(Efficiency_Index) DESC) AS Efficiency_Rank
    FROM
        BinnedPerformance
    GROUP BY
        City, Wind_Speed_Bin)
SELECT
    City,
    Wind_Speed_Range AS '«·”—⁄… «·–Â»Ì… (Sweet Spot)',
    Avg_Efficiency_Index AS 'Highest efficiency index',
    Avg_Power_In_Bin AS 'Average production at this speed'
FROM
    RankedEfficiency
WHERE
    Efficiency_Rank = 1 
ORDER BY
    Avg_Efficiency_Index DESC;
----------------------------------------------------------------------------------------------------------------------------
/* Analysis os energy production based on the seasons */

WITH SeasonalData AS(
    SELECT
        City,
        Power,
        MONTH(TRY_CONVERT(DATE, Date, 101)) AS MonthNum
    FROM
        Wind
    WHERE
        TRY_CONVERT(DATE, Date, 101) IS NOT NULL),
SeasonStats AS(
    SELECT
        City,
        CASE
            WHEN MonthNum IN (12, 1, 2) THEN 'Winter'
            WHEN MonthNum IN (3, 4, 5) THEN 'Spring'
            WHEN MonthNum IN (6, 7, 8) THEN 'Summer'
            WHEN MonthNum IN (9, 10, 11) THEN 'Autumn'
        END AS Season,
        
        AVG(Power) AS Average_Seasonal_Power,
        MAX(Power) AS Max_Power_Recorded,
        COUNT(*) AS Hours_Recorded
    FROM
        SeasonalData
    GROUP BY
        City,
        CASE
            WHEN MonthNum IN (12, 1, 2) THEN 'Winter'
            WHEN MonthNum IN (3, 4, 5) THEN 'Spring'
            WHEN MonthNum IN (6, 7, 8) THEN 'Summer'
            WHEN MonthNum IN (9, 10, 11) THEN 'Autumn'
        END),
RankedSeasons AS(
    SELECT
        City,
        Season,
        Average_Seasonal_Power,
        Max_Power_Recorded,
        RANK() OVER(PARTITION BY City ORDER BY Average_Seasonal_Power DESC) AS Season_Rank
    FROM
        SeasonStats
    WHERE Season IS NOT NULL)
SELECT
    City,
    Season AS Best_Season,
    Average_Seasonal_Power AS Avg_Power,
    Max_Power_Recorded AS Peak_Power
FROM
    RankedSeasons
WHERE
    Season_Rank = 1
ORDER BY
    Average_Seasonal_Power DESC;