-- Implements the data pipeline from raw USPTO data into the normalized model.

USE ip_management;

-- Optional sanity checks on the staging table
SHOW COLUMNS FROM raw_uspto_2023;
SELECT * FROM raw_uspto_2023 LIMIT 2000;

-- Populate jurisdictions from distinct country codes in the raw USPTO data.
-- In this project, jurisdiction name is stored the same as the country code.
INSERT IGNORE INTO jurisdictions (code, name)
SELECT DISTINCT
    country AS code,
    country AS name
FROM raw_uspto_2023
WHERE country IS NOT NULL
  AND country <> '';   -- exclude empty strings

SELECT * FROM jurisdictions LIMIT 10;

-- Populate clients from distinct assignees in the raw USPTO data.
-- contact_email is left NULL because it is not provided in the dataset.
INSERT INTO clients (client_name, contact_email)
SELECT DISTINCT
    assignee AS client_name,
    NULL     AS contact_email
FROM raw_uspto_2023
WHERE assignee IS NOT NULL
  AND assignee <> '';  -- exclude empty strings

SELECT * FROM clients LIMIT 10;

-- Populate patents from raw_uspto_2023.
-- De-duplicate by patent_number so there is exactly one row per patent.
INSERT INTO patents (
    client_id,
    jurisdiction_id,
    patent_number,
    title,
    filing_year,
    grant_year,
    status
)
SELECT
    c.client_id,
    j.jurisdiction_id,
    ru.patent_number,
    ru.first_wipo_field_title,
    ru.application_year,
    ru.grant_year,
    'Granted'        -- all records are granted patents in this dataset
FROM (
    -- Inner query: collapse multiple rows per patent_number into a single row.
    -- GROUP BY requires each selected column to be aggregated; MAX() is used
    -- as a simple, deterministic way to pick one value per patent.
    SELECT
        patent_number,
        MAX(first_wipo_field_title) AS first_wipo_field_title,
        MAX(application_year)       AS application_year,
        MAX(grant_year)             AS grant_year,
        MAX(assignee)               AS assignee,
        MAX(country)                AS country
    FROM raw_uspto_2023
    WHERE patent_number IS NOT NULL
    GROUP BY patent_number
) AS ru
LEFT JOIN clients c
       ON c.client_name = ru.assignee
LEFT JOIN jurisdictions j
       ON j.code = ru.country;

-- Quick verification of populated patents
SELECT * FROM patents LIMIT 50;

-- Generate maintenance-fee deadlines for patents.
-- In this project:
--   - asset_type is always 'patent'
--   - we approximate USPTO 3.5, 7.5, 11.5-year fees with 3, 7, and 11 years
--   - due_year is computed from grant_year at the year level
INSERT INTO deadlines (
    asset_type,
    asset_id,
    deadline_type,
    due_year,
    status
)
SELECT
    'patent',
    p.patent_id,
    '3-year maintenance fee',
    p.grant_year + 3,
    'Open'
FROM patents p
WHERE p.grant_year IS NOT NULL;

INSERT INTO deadlines (
    asset_type,
    asset_id,
    deadline_type,
    due_year,
    status
)
SELECT
    'patent',
    p.patent_id,
    '7-year maintenance fee',
    p.grant_year + 7,
    'Open'
FROM patents p
WHERE p.grant_year IS NOT NULL;

INSERT INTO deadlines (
    asset_type,
    asset_id,
    deadline_type,
    due_year,
    status
)
SELECT
    'patent',
    p.patent_id,
    '11-year maintenance fee',
    p.grant_year + 11,
    'Open'
FROM patents p
WHERE p.grant_year IS NOT NULL;

-- Generate costs linked to those maintenance-fee deadlines.
-- Fee amounts are based on the USPTO patent maintenance fee schedule.
-- 3-year  ≈ 2,150.00
-- 7-year  ≈ 4,040.00
-- 11-year ≈ 8,280.00
INSERT INTO costs (
    asset_type,
    asset_id,
    jurisdiction_id,
    fee_type,
    amount,
    currency,
    due_year
)
SELECT
    'patent',
    p.patent_id,
    p.jurisdiction_id,
    'maintenance',
    2150.00,
    'USD',
    d.due_year
FROM patents p
JOIN deadlines d
  ON d.asset_type = 'patent'
 AND d.asset_id   = p.patent_id
WHERE d.deadline_type = '3-year maintenance fee';

INSERT INTO costs (
    asset_type,
    asset_id,
    jurisdiction_id,
    fee_type,
    amount,
    currency,
    due_year
)
SELECT
    'patent',
    p.patent_id,
    p.jurisdiction_id,
    'maintenance',
    4040.00,
    'USD',
    d.due_year
FROM patents p
JOIN deadlines d
  ON d.asset_type = 'patent'
 AND d.asset_id   = p.patent_id
WHERE d.deadline_type = '7-year maintenance fee';

INSERT INTO costs (
    asset_type,
    asset_id,
    jurisdiction_id,
    fee_type,
    amount,
    currency,
    due_year
)
SELECT
    'patent',
    p.patent_id,
    p.jurisdiction_id,
    'maintenance',
    8280.00,
    'USD',
    d.due_year
FROM patents p
JOIN deadlines d
  ON d.asset_type = 'patent'
 AND d.asset_id   = p.patent_id
WHERE d.deadline_type = '11-year maintenance fee';
