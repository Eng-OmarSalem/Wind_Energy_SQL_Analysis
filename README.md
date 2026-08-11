[README.md](https://github.com/user-attachments/files/30952421/README.md)
<div align="center">

# 🌬️ Wind Energy SQL Analysis

### T-SQL Analysis of European Wind Power Production

![SQL Server](https://img.shields.io/badge/Microsoft%20SQL%20Server-CC2927?style=for-the-badge&logo=microsoft-sql-server&logoColor=white)
![T-SQL](https://img.shields.io/badge/T--SQL-4B5563?style=for-the-badge)
![Data Analysis](https://img.shields.io/badge/Data-Analysis-orange?style=for-the-badge)

</div>

---

## 📌 Overview

**Wind Energy SQL Analysis** is a T-SQL project that explores hourly weather and power-generation data across **21 European cities** throughout **2020**, using Microsoft SQL Server.

The project answers real operational questions about wind farms: which cities produce the most power, how output changes by hour/month/season, how wind gusts and direction affect stability, and where each turbine's peak efficiency "sweet spot" lies — all built with clean, well-commented SQL using CTEs and window functions.

---

## 🗃️ Dataset

**File:** `Wind.csv` — 8,784 hourly records (366 days × 24 hours) for the year 2020.

| Column | Description |
|---|---|
| `Date`, `Time` | Timestamp of the reading |
| `temperature_2m` | Air temperature at 2m (°C) |
| `relativehumidity_2m` | Relative humidity at 2m (%) |
| `dewpoint_2m` | Dew point at 2m (°C) |
| `windspeed_10m` / `windspeed_100m` | Wind speed at 10m and 100m (turbine hub height), in m/s |
| `winddirection_10m` / `winddirection_100m` | Wind direction in degrees |
| `windgusts_10m` | Wind gust speed at 10m |
| `Power` | Power output |
| `City` | One of 21 European cities |

**Cities covered:** Amsterdam, Athens, Barcelona, Berlin, Brussels, Budapest, Dublin, Grenoble, Helsinki, Innsbruck, Lisbon, London, Madrid, Moscow, Oslo, Paris, Prague, Rome, Stockholm, Warsaw, Zurich.

---

## 🔍 Key Analyses (`Wind_Energy.sql`)

The script is organized into independent, comment-separated sections:

1. **Average Power & Wind Speed by City** — ranks cities by average power output and wind speed at hub height.
2. **Power Production by Hour of Day** — average output per hour, isolated for a selected city.
3. **Top Producing City per Year** — ranks cities by total yearly power using `RANK() OVER(...)`.
4. **Top Producing City per Month** — same logic applied month by month.
5. **Daily Power Trend for a City** — total power produced per calendar day.
6. **Largest Hour-over-Hour Power Ramp-Ups** — uses `LAG()` to detect the fastest increases in output between consecutive hours.
7. **Gust Factor Categorization** — classifies conditions into *Smooth / Gusty / Stormy / Extreme* based on the gust-to-wind-speed ratio, then compares average power per category.
8. **Wind Direction Stability Analysis** — measures hour-to-hour directional change and groups it by compass sector (N, NE, E, SE, S, SW, W, NW).
9. **Effect of Humidity on Stormy Winds** — cross-tabulates atmospheric conditions (Fog/Humid/Dry/Moderate) with wind turbulence type.
10. **Wind Shear Analysis** — studies the speed difference between 10m and 100m and its relation to power output.
11. **Humidity vs. Wind-Speed Efficiency Bins** — bins wind speed into 2 m/s ranges and cross-references with humidity level to see the effect on output.
12. **Turbine Efficiency "Sweet Spot"** — computes an efficiency index (`Power / windspeed_100m³`) per 1 m/s speed bin to find each city's most efficient operating range.
13. **Seasonal Power Production** — ranks Winter / Spring / Summer / Autumn by average and peak power per city.

---

## 🛠️ Tools & Techniques

- **Microsoft SQL Server (T-SQL)**
- **CTEs (Common Table Expressions)** for multi-step, readable transformations
- **Window Functions:** `RANK() OVER(...)`, `LAG() OVER(...)`
- **Safe date/time parsing:** `TRY_CONVERT`, `TRY_CAST`
- **Conditional logic:** `CASE WHEN` for categorization (gust factor, humidity, wind sector, season)
- **Aggregations:** `AVG`, `SUM`, `MAX`, `MIN`, `COUNT` with `GROUP BY`

---

## 🚀 How to Use

1. Create a database in SQL Server Management Studio (SSMS) or Azure Data Studio.
2. Import `Wind.csv` into a table named `Wind` (via the **Import Flat File** wizard, matching the column list above).
3. Open `Wind_Energy.sql` and run each section independently — they are separated by comments and horizontal dividers.
4. Adjust the hardcoded `City = 'Berlin'` filters in a few queries to explore any other city in the dataset.

---

## 📬 Contact Me

<div align="center">

[![GitHub](https://img.shields.io/badge/GitHub-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/Eng-OmarSalem)
[![Portfolio](https://img.shields.io/badge/Portfolio-4B5563?style=for-the-badge)](https://gamma.app/docs/Copy-of-Brand-Partnership-Proposal-lrp9yrhau9gdpj1)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/eng-omarsalem)

</div>

---

<div align="center">

Made with 🌬️ and T-SQL

</div>
