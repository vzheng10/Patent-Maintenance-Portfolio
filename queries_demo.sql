-- Contains “showcase” queries that demonstrate how the schema can be used
-- for patent portfolio maintenance analytics, including:
--   - Maintenance fee schedule per patent (patents → deadlines)
--   - Total expected maintenance fees by year and jurisdiction
--   - Patents approaching expiry, assuming a 20-year life from filing_year

-- =========================================================
-- Optional sanity checks on populated tables
-- =========================================================

-- Row counts in the core normalized tables
SELECT COUNT(*) AS patents_count   FROM patents;
SELECT COUNT(*) AS deadlines_count FROM deadlines;
SELECT COUNT(*) AS costs_count     FROM costs;

-- Distribution of maintenance-fee deadline types
SELECT
    deadline_type,
    COUNT(*) AS count_per_type
FROM deadlines
GROUP BY deadline_type;

-- =========================================================
-- 1. Maintenance fee schedule (3, 7, and 11 years) for each patent
--    Shows, for each patent, the maintenance deadlines generated from grant_year.
-- =========================================================
SELECT
    p.patent_number,
    p.title,
    p.grant_year,
    d.deadline_type,
    d.due_year
FROM patents p
JOIN deadlines d   -- inner join: only patents that have at least one deadline
  ON d.asset_type = 'patent'
 AND d.asset_id   = p.patent_id
ORDER BY
    p.patent_number ASC,
    d.due_year ASC;  -- ascending year (default) so deadlines appear in chronological order

-- =========================================================
-- 2. Total expected maintenance revenue by year and jurisdiction
--    Aggregates maintenance fees from the costs table.
--    Jurisdictions with missing or blank names are labeled as 'Unknown'.
-- =========================================================
SELECT
    cst.due_year,  -- maintenance-fee year from the costs table
    COALESCE(NULLIF(j.name, ''), 'Unknown') AS jurisdiction,
    SUM(cst.amount) AS total_expected_fees
FROM costs cst
JOIN patents p
  ON cst.asset_type = 'patent'
 AND cst.asset_id   = p.patent_id
LEFT JOIN jurisdictions j
  ON p.jurisdiction_id = j.jurisdiction_id
GROUP BY
    cst.due_year,
    COALESCE(NULLIF(j.name, ''), 'Unknown')  -- group missing/blank names into 'Unknown'
ORDER BY
    cst.due_year,
    total_expected_fees DESC;

-- =========================================================
-- 3. Patents “expiring soon” (within a 20-year term from filing_year)
--    Identifies patents whose assumed 20-year term ends in a given window.
--    Here, we show patents expiring between 2025 and 2030 (inclusive).
-- =========================================================
SELECT
    p.patent_number,
    p.title,
    p.filing_year,
    (p.filing_year + 20) AS expiry_year,  -- simplified 20-year term from filing_year
    c.client_name,
    j.name AS jurisdiction
FROM patents p
LEFT JOIN clients c
       ON p.client_id = c.client_id
LEFT JOIN jurisdictions j
       ON p.jurisdiction_id = j.jurisdiction_id
WHERE (p.filing_year + 20) BETWEEN 2025 AND 2030
ORDER BY
    expiry_year,
    p.patent_number;
