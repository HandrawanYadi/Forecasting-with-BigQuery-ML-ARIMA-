-- 1. Aggregate daily → weekly segment demand
CREATE OR REPLACE TABLE `<your_project>.<your_dataset>.segment_weekly` AS
SELECT
  DATE_TRUNC(date, WEEK(MONDAY)) AS week_start,
  segment,
  SUM(units_sold) AS weekly_units
FROM `<your_project>.<your_dataset>.fmcg_daily`
GROUP BY week_start, segment
ORDER BY week_start, segment;


-- 2. Train ARIMA+ (multi-series)
CREATE OR REPLACE MODEL `<your_project>.<your_dataset>.segment_arima_model`
OPTIONS(
  MODEL_TYPE = 'ARIMA_PLUS',
  TIME_SERIES_TIMESTAMP_COL = 'week_start',
  TIME_SERIES_DATA_COL = 'weekly_units',
  TIME_SERIES_ID_COL = 'segment',
  HOLIDAY_REGION = 'US'
) AS
SELECT
  week_start,
  segment,
  weekly_units
FROM `<your_project>.<your_dataset>.segment_weekly`
ORDER BY week_start;


-- 3. Generate 16-week forecast
CREATE OR REPLACE TABLE `<your_project>.<your_dataset>.segment_forecast` AS
SELECT
  segment,
  forecast_timestamp AS week_start,
  forecast_value AS forecast_units,
  prediction_interval_lower AS lower_bound,
  prediction_interval_upper AS upper_bound
FROM ML.FORECAST(
  MODEL `<your_project>.<your_dataset>.segment_arima_model`,
  STRUCT(16 AS horizon)
);


-- 4. Compute last-8-weeks SKU mix per segment
CREATE OR REPLACE TABLE `<your_project>.<your_dataset>.sku_mix` AS
WITH recent AS (
  SELECT
    sku,
    segment,
    SUM(units_sold) AS units_last_8w
  FROM `<your_project>.<your_dataset>.fmcg_daily`
  WHERE date >= DATE_SUB(
      (SELECT MAX(date) FROM `<your_project>.<your_dataset>.fmcg_daily`), 
      INTERVAL 8 WEEK
  )
  GROUP BY sku, segment
),
seg_totals AS (
  SELECT
    segment,
    SUM(units_last_8w) AS segment_total
  FROM recent
  GROUP BY segment
)
SELECT
  r.sku,
  r.segment,
  r.units_last_8w,
  r.units_last_8w / st.segment_total AS mix_ratio
FROM recent r
JOIN seg_totals st USING (segment);


-- 5. Allocate segment forecast → SKU forecast
CREATE OR REPLACE TABLE `<your_project>.<your_dataset>.sku_forecast` AS
SELECT
  f.segment,
  m.sku,
  f.week_start,
  f.forecast_units * m.mix_ratio AS sku_forecast_units
FROM `<your_project>.<your_dataset>.segment_forecast` f
JOIN `<your_project>.<your_dataset>.sku_mix` m USING (segment)
ORDER BY segment, sku, week_start;


-- 6. Final Power BI export table
CREATE OR REPLACE TABLE `<your_project>.<your_dataset>.bi_export` AS
SELECT
  w.week_start,
  w.segment,
  w.weekly_units AS actual_units,
  f.forecast_units,
  f.lower_bound,
  f.upper_bound
FROM `<your_project>.<your_dataset>.segment_weekly` w
LEFT JOIN `<your_project>.<your_dataset>.segment_forecast` f
  USING (segment, week_start)
ORDER BY segment, week_start;
