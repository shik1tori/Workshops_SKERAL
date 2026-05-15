SELECT * FROM `skelar-496409.task_1.marketing_ads_raw`;

-- Крок 1 — Дедублікація
WITH
  dedup
  AS
  (
    SELECT *
    FROM (
        SELECT
        *,
        ROW_NUMBER() OVER (
                PARTITION BY ad_id, date
                ORDER BY timestamp DESC
            ) AS rn
      FROM `skelar-496409.task_1.marketing_ads_raw`
    )
    WHERE rn = 1
),

-- Крок 2 — Денні метрики
daily AS(
  SELECT
    source,
    date,
    SUM(spend) AS spend,
    SUM(impressions) AS impressions,
    SUM(clicks) AS clicks,
    SUM(installs) AS installs,
    SUM(registrations) AS registrations
FROM dedup
GROUP BY source, date),

-- Крок 3 — Метрики по каналу за весь період
final AS(
  SELECT
    source,
    SUM(spend) AS total_spend,
    SUM(impressions) AS total_impressions,
    SUM(clicks) AS total_clicks,
    SUM(installs) AS total_installs,
    SUM(registrations) AS total_registrations
FROM daily
GROUP BY source
)

SELECT
  source,
  ROUND(total_spend) AS total_spend,
  ROUND(SAFE_DIVIDE(total_spend, total_impressions) * 1000, 2) AS cpm,
  ROUND(SAFE_DIVIDE(total_clicks, total_impressions) * 100, 2) AS ctr_pct,
  ROUND(SAFE_DIVIDE(total_installs, total_clicks) * 100, 2) AS cr_click_install_pct,
  ROUND(SAFE_DIVIDE(total_registrations, total_installs) * 100, 2) AS cr_install_reg_pct,
  ROUND(SAFE_DIVIDE(total_spend, total_registrations), 2) AS cac,
  -- Bonus: LTV
  CASE
          WHEN source = 'tiktok' THEN 8.50
          WHEN source = 'meta' THEN 6.20
          WHEN source = 'google' THEN 12.40
  END AS ltv,

  ROUND
  (
    CASE
        WHEN source = 'tiktok'
          THEN SAFE_DIVIDE(8.50, SAFE_DIVIDE (total_spend, total_registrations))

        WHEN source = 'meta'
          THEN SAFE_DIVIDE(6.20, SAFE_DIVIDE (total_spend, total_registrations))

        WHEN source = 'google'
          THEN SAFE_DIVIDE(12.40, SAFE_DIVIDE (total_spend, total_registrations))
  END, 2) AS ltv_cac

FROM final
ORDER BY cac;