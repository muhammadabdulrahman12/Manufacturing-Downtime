USE Manufacturing_Downtime_DB;
GO

SELECT DB_NAME() AS Current_Database;

SELECT name AS Table_Name
FROM sys.tables
ORDER BY name;

SELECT 'fact_machine_shift' AS Table_Name, COUNT(*) AS Row_Count
FROM dbo.fact_machine_shift
UNION ALL
SELECT 'downtime_events', COUNT(*) FROM dbo.downtime_events
UNION ALL
SELECT 'machines', COUNT(*) FROM dbo.machines
UNION ALL
SELECT 'products', COUNT(*) FROM dbo.products
UNION ALL
SELECT 'dim_date', COUNT(*) FROM dbo.dim_date
UNION ALL
SELECT 'dim_shift', COUNT(*) FROM dbo.dim_shift;
GO

IF COL_LENGTH('dbo.fact_machine_shift', 'Run_Time_Min') IS NULL
BEGIN
    ALTER TABLE dbo.fact_machine_shift
    ADD Run_Time_Min AS (planned_minutes - Downtime_Min);
END;
GO

SELECT
    fk.name AS Foreign_Key_Name,
    OBJECT_NAME(fk.parent_object_id) AS From_Table,
    OBJECT_NAME(fk.referenced_object_id) AS To_Table
FROM sys.foreign_keys AS fk
ORDER BY From_Table, To_Table;

SELECT 'machines' AS Table_Name,
       COUNT(*) AS Total_Rows,
       COUNT(DISTINCT machine_id) AS Distinct_Keys
FROM dbo.machines
UNION ALL
SELECT 'products', COUNT(*), COUNT(DISTINCT product_id)
FROM dbo.products
UNION ALL
SELECT 'dim_shift', COUNT(*), COUNT(DISTINCT shift)
FROM dbo.dim_shift
UNION ALL
SELECT 'dim_date', COUNT(*), COUNT(DISTINCT [Date])
FROM dbo.dim_date
UNION ALL
SELECT 'fact_machine_shift', COUNT(*), COUNT(DISTINCT log_id)
FROM dbo.fact_machine_shift
UNION ALL
SELECT 'downtime_events', COUNT(*), COUNT(DISTINCT event_id)
FROM dbo.downtime_events;

SELECT
    Time_Swapped,
    COUNT(*) AS Total_Records
FROM dbo.downtime_events
GROUP BY Time_Swapped
ORDER BY Time_Swapped;

SELECT COUNT(*) AS Records_With_Missing_Quality_Data
FROM dbo.fact_machine_shift
WHERE Rejected_Units IS NULL
   OR Good_Units IS NULL
   OR Scrap_Cost_USD IS NULL;

SELECT
    Quality_Data_Valid,
    COUNT(*) AS Total_Records
FROM dbo.fact_machine_shift
GROUP BY Quality_Data_Valid
ORDER BY Quality_Data_Valid;

SELECT COUNT(*) AS Fact_Records_Without_Machine
FROM dbo.fact_machine_shift AS f
LEFT JOIN dbo.machines AS m
    ON m.machine_id = f.machine_id
WHERE m.machine_id IS NULL;

SELECT COUNT(*) AS Fact_Records_Without_Product
FROM dbo.fact_machine_shift AS f
LEFT JOIN dbo.products AS p
    ON p.product_id = f.product_id
WHERE p.product_id IS NULL;

SELECT COUNT(*) AS Fact_Records_Without_Date
FROM dbo.fact_machine_shift AS f
LEFT JOIN dbo.dim_date AS d
    ON d.[Date] = f.prod_date
WHERE d.[Date] IS NULL;

SELECT COUNT(*) AS Fact_Records_Without_Shift
FROM dbo.fact_machine_shift AS f
LEFT JOIN dbo.dim_shift AS s
    ON s.shift = f.shift
WHERE s.shift IS NULL;

SELECT COUNT(*) AS Events_Without_Machine
FROM dbo.downtime_events AS e
LEFT JOIN dbo.machines AS m
    ON m.machine_id = e.machine_id
WHERE m.machine_id IS NULL;

SELECT COUNT(*) AS Events_Without_Date
FROM dbo.downtime_events AS e
LEFT JOIN dbo.dim_date AS d
    ON d.[Date] = e.event_date
WHERE d.[Date] IS NULL;

SELECT COUNT(*) AS Events_Without_Matching_Fact_Record
FROM dbo.downtime_events AS e
LEFT JOIN dbo.fact_machine_shift AS f
    ON f.slot_key = e.slot_key
WHERE f.slot_key IS NULL;

SELECT
    COUNT(*) AS Total_Fact_Records,
    COUNT(DISTINCT slot_key) AS Distinct_Slot_Keys
FROM dbo.fact_machine_shift;

SELECT
    COUNT(*) AS Matched_Event_Records,
    SUM(CASE WHEN e.machine_id <> f.machine_id THEN 1 ELSE 0 END) AS Machine_Mismatches,
    SUM(CASE WHEN e.shift <> f.shift THEN 1 ELSE 0 END) AS Shift_Mismatches,
    SUM(CASE WHEN e.event_date <> f.prod_date THEN 1 ELSE 0 END) AS Date_Mismatches
FROM dbo.downtime_events AS e
INNER JOIN dbo.fact_machine_shift AS f
    ON f.slot_key = e.slot_key;
GO

SELECT
    SUM(Downtime_Min) AS Total_Downtime_Minutes,
    SUM(planned_minutes) AS Total_Planned_Minutes,
    SUM(Run_Time_Min) AS Total_Run_Time_Minutes,
    SUM(total_units) AS Total_Units
FROM dbo.fact_machine_shift;

SELECT
    (SELECT SUM(Downtime_Min)
     FROM dbo.fact_machine_shift) AS Fact_Table_Downtime_Minutes,
    (SELECT SUM(Duration_Min)
     FROM dbo.downtime_events) AS Event_Table_Downtime_Minutes,
    (SELECT SUM(Downtime_Min)
     FROM dbo.fact_machine_shift)
      -
    (SELECT SUM(Duration_Min)
     FROM dbo.downtime_events) AS Difference_Minutes;

SELECT
    CASE WHEN SUM(Downtime_Min) = 131004
         THEN 'OK' ELSE 'MISMATCH' END AS Downtime_Check,
    CASE WHEN SUM(planned_minutes) = 907200
         THEN 'OK' ELSE 'MISMATCH' END AS Planned_Time_Check,
    CASE WHEN SUM(Run_Time_Min) = 776196
         THEN 'OK' ELSE 'MISMATCH' END AS Run_Time_Check,
    CASE WHEN SUM(total_units) = 906244
         THEN 'OK' ELSE 'MISMATCH' END AS Production_Units_Check,
    CASE WHEN SUM(Run_Time_Min) + SUM(Downtime_Min) = SUM(planned_minutes)
         THEN 'OK' ELSE 'MISMATCH' END AS Time_Reconciliation_Check
FROM dbo.fact_machine_shift;
GO

SELECT
    COUNT(*) AS Total_Machine_Shifts,
    COUNT(DISTINCT machine_id) AS Total_Machines,
    SUM(planned_minutes) AS Planned_Minutes,
    SUM(Run_Time_Min) AS Run_Time_Minutes,
    SUM(Downtime_Min) AS Downtime_Minutes,
    ROUND(SUM(Downtime_Min) / 60.0, 2) AS Downtime_Hours,
    ROUND(SUM(Run_Time_Min) * 100.0 / NULLIF(SUM(planned_minutes), 0), 2) AS Availability_Pct,
    ROUND(SUM(Downtime_Min) * 100.0 / NULLIF(SUM(planned_minutes), 0), 2) AS Downtime_Pct,
    ROUND(AVG(CAST(Downtime_Min AS FLOAT)), 2) AS Avg_Downtime_Per_Shift
FROM dbo.fact_machine_shift;

WITH Machine_OEE AS
(
    SELECT
        f.machine_id,
        SUM(f.Run_Time_Min) * 100.0
            / NULLIF(SUM(f.planned_minutes), 0) AS Availability_Pct,
        SUM(m.ideal_cycle_time_sec * f.total_units / 60.0) * 100.0
            / NULLIF(SUM(f.Run_Time_Min), 0) AS Performance_Pct,
        (SUM(f.total_units)
            - SUM(ISNULL(TRY_CAST(f.Rejected_Units AS INT), 0))) * 100.0
            / NULLIF(SUM(f.total_units), 0) AS Quality_Pct
    FROM dbo.fact_machine_shift AS f
    INNER JOIN dbo.machines AS m
        ON m.machine_id = f.machine_id
    GROUP BY f.machine_id
)
SELECT
    machine_id,
    ROUND(Availability_Pct, 2) AS Availability_Pct,
    ROUND(Performance_Pct, 2) AS Performance_Pct,
    ROUND(Quality_Pct, 2) AS Quality_Pct,
    ROUND(Availability_Pct * Performance_Pct * Quality_Pct / 10000.0, 2) AS OEE_Pct
FROM Machine_OEE
ORDER BY machine_id;

WITH Overall_OEE AS
(
    SELECT
        SUM(f.Run_Time_Min) * 100.0
            / NULLIF(SUM(f.planned_minutes), 0) AS Availability_Pct,
        SUM(m.ideal_cycle_time_sec * f.total_units / 60.0) * 100.0
            / NULLIF(SUM(f.Run_Time_Min), 0) AS Performance_Pct,
        (SUM(f.total_units)
            - SUM(ISNULL(TRY_CAST(f.Rejected_Units AS INT), 0))) * 100.0
            / NULLIF(SUM(f.total_units), 0) AS Quality_Pct
    FROM dbo.fact_machine_shift AS f
    INNER JOIN dbo.machines AS m
        ON m.machine_id = f.machine_id
)
SELECT
    ROUND(Availability_Pct, 2) AS Availability_Pct,
    ROUND(Performance_Pct, 2) AS Performance_Pct,
    ROUND(Quality_Pct, 2) AS Quality_Pct,
    ROUND(Availability_Pct * Performance_Pct * Quality_Pct / 10000.0, 2) AS OEE_Pct
FROM Overall_OEE;
GO

SELECT
    m.machine_id,
    m.machine_name,
    m.line,
    m.machine_type,
    COUNT(*) AS Total_Shifts,
    SUM(f.planned_minutes) AS Planned_Minutes,
    SUM(f.Downtime_Min) AS Downtime_Minutes,
    ROUND(SUM(f.Downtime_Min) / 60.0, 2) AS Downtime_Hours,
    ROUND(SUM(f.Downtime_Min) * 100.0
          / NULLIF(SUM(f.planned_minutes), 0), 2) AS Downtime_Rate_Pct,
    ROUND(SUM(f.Downtime_Min) * 100.0
          / NULLIF((SELECT SUM(Downtime_Min)
                    FROM dbo.fact_machine_shift), 0), 2) AS Share_Of_Total_Downtime_Pct
FROM dbo.fact_machine_shift AS f
INNER JOIN dbo.machines AS m
    ON m.machine_id = f.machine_id
GROUP BY
    m.machine_id,
    m.machine_name,
    m.line,
    m.machine_type
ORDER BY Downtime_Minutes DESC;

SELECT TOP (5)
    m.machine_id,
    m.machine_name,
    SUM(f.Downtime_Min) AS Downtime_Minutes
FROM dbo.fact_machine_shift AS f
INNER JOIN dbo.machines AS m
    ON m.machine_id = f.machine_id
GROUP BY m.machine_id, m.machine_name
ORDER BY Downtime_Minutes DESC;

SELECT
    s.shift,
    s.shift_name,
    COUNT(*) AS Total_Machine_Shifts,
    SUM(f.planned_minutes) AS Planned_Minutes,
    SUM(f.Downtime_Min) AS Downtime_Minutes,
    ROUND(SUM(f.Downtime_Min) / 60.0, 2) AS Downtime_Hours,
    ROUND(SUM(f.Downtime_Min) * 100.0
          / NULLIF(SUM(f.planned_minutes), 0), 2) AS Downtime_Rate_Pct
FROM dbo.fact_machine_shift AS f
INNER JOIN dbo.dim_shift AS s
    ON s.shift = f.shift
GROUP BY s.shift, s.shift_name, s.shift_order
ORDER BY s.shift_order;
GO

SELECT
    reason_code,
    COUNT(*) AS Total_Events,
    SUM(Duration_Min) AS Downtime_Minutes,
    ROUND(SUM(Duration_Min) / 60.0, 2) AS Downtime_Hours,
    ROUND(SUM(Duration_Min) * 100.0
          / NULLIF((SELECT SUM(Duration_Min)
                    FROM dbo.downtime_events), 0), 2) AS Share_Of_Downtime_Pct
FROM dbo.downtime_events
GROUP BY reason_code
ORDER BY Downtime_Minutes DESC;

WITH Reason_Downtime AS
(
    SELECT
        reason_code,
        COUNT(*) AS Total_Events,
        SUM(Duration_Min) AS Downtime_Minutes
    FROM dbo.downtime_events
    GROUP BY reason_code
)
SELECT
    reason_code,
    Total_Events,
    Downtime_Minutes,
    ROUND(Downtime_Minutes * 100.0
          / NULLIF(SUM(Downtime_Minutes) OVER (), 0), 2) AS Contribution_Pct,
    ROUND(SUM(Downtime_Minutes) OVER
          (ORDER BY Downtime_Minutes DESC, reason_code
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) * 100.0
          / NULLIF(SUM(Downtime_Minutes) OVER (), 0), 2) AS Cumulative_Pct
FROM Reason_Downtime
ORDER BY Downtime_Minutes DESC, reason_code;

SELECT
    Downtime_Type,
    COUNT(*) AS Total_Events,
    SUM(Duration_Min) AS Downtime_Minutes,
    ROUND(SUM(Duration_Min) / 60.0, 2) AS Downtime_Hours,
    ROUND(SUM(Duration_Min) * 100.0
          / NULLIF((SELECT SUM(Duration_Min)
                    FROM dbo.downtime_events), 0), 2) AS Share_Of_Downtime_Pct
FROM dbo.downtime_events
GROUP BY Downtime_Type
ORDER BY Downtime_Minutes DESC;

SELECT
    reason_code,
    Downtime_Type,
    COUNT(*) AS Event_Count,
    SUM(Duration_Min) AS Total_Downtime_Minutes
FROM dbo.downtime_events
GROUP BY reason_code, Downtime_Type
ORDER BY Total_Downtime_Minutes DESC;
GO

SELECT
    d.[Year],
    d.Month_Num,
    d.Month_Name,
    d.Year_Month,
    COUNT(*) AS Total_Machine_Shifts,
    SUM(f.planned_minutes) AS Planned_Minutes,
    SUM(f.Downtime_Min) AS Downtime_Minutes,
    ROUND(SUM(f.Downtime_Min) / 60.0, 2) AS Downtime_Hours,
    ROUND(SUM(f.Downtime_Min) * 100.0
          / NULLIF(SUM(f.planned_minutes), 0), 2) AS Downtime_Rate_Pct
FROM dbo.fact_machine_shift AS f
INNER JOIN dbo.dim_date AS d
    ON d.[Date] = f.prod_date
GROUP BY d.[Year], d.Month_Num, d.Month_Name, d.Year_Month
ORDER BY d.[Year], d.Month_Num;

SELECT
    f.machine_id,
    d.Year_Month,
    ROUND(SUM(f.Run_Time_Min) * 100.0
          / NULLIF(SUM(f.planned_minutes), 0), 2) AS Availability_Pct
FROM dbo.fact_machine_shift AS f
INNER JOIN dbo.dim_date AS d
    ON d.[Date] = f.prod_date
GROUP BY f.machine_id, d.Year_Month
ORDER BY f.machine_id, d.Year_Month;
GO

SELECT
    s.shift_name,
    SUM(f.total_units) AS Total_Units,
    SUM(f.Downtime_Min) AS Downtime_Minutes
FROM dbo.fact_machine_shift AS f
INNER JOIN dbo.dim_shift AS s
    ON s.shift = f.shift
GROUP BY s.shift_name, s.shift_order
ORDER BY s.shift_order;

SELECT
    p.product_id,
    p.product_name,
    p.product_family,
    SUM(f.total_units) AS Total_Units,
    SUM(ISNULL(TRY_CAST(f.Rejected_Units AS INT), 0)) AS Rejected_Units,
    ROUND(SUM(ISNULL(TRY_CAST(f.Rejected_Units AS INT), 0)) * 100.0
          / NULLIF(SUM(f.total_units), 0), 2) AS Reject_Rate_Pct,
    SUM(ISNULL(f.Scrap_Cost_USD, 0)) AS Scrap_Cost_USD
FROM dbo.fact_machine_shift AS f
INNER JOIN dbo.products AS p
    ON p.product_id = f.product_id
GROUP BY p.product_id, p.product_name, p.product_family
ORDER BY Total_Units DESC;
GO
