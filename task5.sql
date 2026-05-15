WITH
    dedup
    AS
    (
        SELECT *
        FROM (
        SELECT *,
                ROW_NUMBER() OVER (
                PARTITION BY ad_id, date
                ORDER BY timestamp DESC
            ) AS rn
            FROM `skelar-496409.task_1
    .marketing_ads_raw`
    )
    WHERE rn = 1
)

SELECT
    source,
    FORMAT_DATE('%Y-%m', date) AS month,

    ROUND(SUM(spend), 2) AS total_spend,
    SUM(registrations) AS registrations,

    ROUND(
        SAFE_DIVIDE(SUM(spend), SUM(registrations)),
        2
    ) AS cac

FROM dedup
GROUP BY source, month
ORDER BY month, cac;