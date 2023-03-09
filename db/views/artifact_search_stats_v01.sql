WITH click_count AS (
  SELECT
    JSONB_PATH_QUERY(link_clicks, '$.artifact_id')::bigint as artifact_id,
    COUNT(*) as click_count
  FROM
    search_logs
  GROUP BY
    artifact_id
),
returned_count AS (
  SELECT
    JSONB_ARRAY_ELEMENTS(returned_artifact_ids)::bigint as artifact_id,
    COUNT(*) as returned_count
  FROM
    search_logs
  GROUP BY
    artifact_id
)
SELECT
  COALESCE(c.artifact_id, r.artifact_id) AS artifact_id, c.click_count, r.returned_count
FROM
  click_count c
FULL OUTER JOIN
  returned_count r ON r.artifact_id = c.artifact_id;
