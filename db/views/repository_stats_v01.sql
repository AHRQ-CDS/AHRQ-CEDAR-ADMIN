WITH concept_count as (
  SELECT a.id, COUNT(ac.concept_id) as count_all FROM artifacts a
  LEFT JOIN artifacts_concepts ac ON a.id = ac.artifact_id
  GROUP BY a.id
)
SELECT
  a.repository_id,
  a.artifact_type,
  COUNT(*) AS total,
  SUM(
    CASE WHEN (
      (a.title IS NULL OR LENGTH(a.title) = 0)
    )
    THEN 1 ELSE 0 END) AS missing_title,
  SUM(
    CASE WHEN (
      (a.description IS NULL OR LENGTH(a.description) = 0)
    )
    THEN 1 ELSE 0 END) AS missing_desc,
  SUM(
    CASE WHEN (
      (a.keywords IS NULL OR JSONB_ARRAY_LENGTH(a.keywords) = 0)
    )
    THEN 1 ELSE 0 END) AS missing_keyword,
  SUM(
    CASE WHEN (
      (ac.count_all IS NULL OR ac.count_all = 0)
    )
    THEN 1 ELSE 0 END) AS missing_concept
FROM
  artifacts a
INNER JOIN
  concept_count ac on a.id = ac.id
GROUP BY
  a.repository_id, a.artifact_type
ORDER BY
  total DESC;
