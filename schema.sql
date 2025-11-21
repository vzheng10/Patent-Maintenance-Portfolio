-- Define the database structure for patent portfolio maintenance analytics.
-- This schema models:
--   - clients (patent owners),
--   - jurisdictions (patent offices / countries),
--   - normalized patent records,
--   - maintenance-fee deadlines,
--   - and associated maintenance costs,
-- using USPTO 2023 granted patent data as the source.

CREATE DATABASE IF NOT EXISTS ip_management;
USE ip_management;

-- Clients → companies or entities that own patents in this portfolio
-- contact_email is optional and not populated from the USPTO dataset.
CREATE TABLE clients (
    client_id      INT AUTO_INCREMENT PRIMARY KEY,
    client_name    VARCHAR(255) NOT NULL,
    contact_email  VARCHAR(255)
) ENGINE=InnoDB;

-- Jurisdictions → patent office / country code
-- In this project, name is the same as code because the USPTO dataset
-- only provides country codes (e.g. 'US', 'JP', 'DE') and not full names.
CREATE TABLE jurisdictions (
    jurisdiction_id INT AUTO_INCREMENT PRIMARY KEY,
    code            VARCHAR(10)  NOT NULL UNIQUE,  -- e.g. 'US', 'CN', 'JP'
    name            VARCHAR(100) NOT NULL          -- stored same as code in this project
) ENGINE=InnoDB;

-- Patents → core patent data linked to client and jurisdiction
-- In this project, all records come from a granted-patent dataset,
-- so status is set to 'Granted' for every row.
CREATE TABLE patents (
    patent_id       INT AUTO_INCREMENT PRIMARY KEY,
    client_id       INT NOT NULL,
    jurisdiction_id INT,
    patent_number   VARCHAR(50) NOT NULL UNIQUE,
    title           VARCHAR(500) NOT NULL,
    filing_year     YEAR,           -- year-level because source data is year-only
    grant_year      YEAR,           -- year-level because source data is year-only
    status          VARCHAR(50),    -- set to 'Granted' for all imported patents
    CONSTRAINT fk_patents_client
        FOREIGN KEY (client_id) REFERENCES clients (client_id),
    CONSTRAINT fk_patents_jurisdiction
        FOREIGN KEY (jurisdiction_id) REFERENCES jurisdictions (jurisdiction_id)
) ENGINE=InnoDB;  
    
-- Deadlines → maintenance-fee deadlines for patents
-- In this project:
--   - asset_type is always 'patent'
--   - we only model 3-year, 7-year, and 11-year maintenance fee deadlines
--   - timing is stored at the year level (due_year), not exact dates
CREATE TABLE deadlines (
    deadline_id    INT AUTO_INCREMENT PRIMARY KEY,
    asset_type     VARCHAR(20) NOT NULL,   -- always 'patent' in this project
    asset_id       INT NOT NULL,           -- references patent_id when asset_type = 'patent'
    deadline_type  VARCHAR(100) NOT NULL,  -- e.g. '3-year maintenance fee', '7-year maintenance fee'
    due_year       YEAR NOT NULL,          -- grant_year + 3, +7, +11
    status         VARCHAR(30) DEFAULT 'Open'
) ENGINE=InnoDB;

-- Costs → monetary amounts associated with those patent maintenance deadlines
-- In this project:
--   - asset_type is always 'patent'
--   - fee_type is used for maintenance fees only
--   - due_year matches deadlines.due_year
CREATE TABLE costs (
    cost_id         INT AUTO_INCREMENT PRIMARY KEY,
    asset_type      VARCHAR(20) NOT NULL,  -- always 'patent' in this project
    asset_id        INT NOT NULL,          -- references patent_id when asset_type = 'patent'
    jurisdiction_id INT,
    fee_type        VARCHAR(50),           -- e.g. 'maintenance'
    amount          DECIMAL(12, 2),
    currency        VARCHAR(10),
    due_year        YEAR,                  -- same year as the associated deadline
    CONSTRAINT fk_costs_jurisdiction
        FOREIGN KEY (jurisdiction_id) REFERENCES jurisdictions (jurisdiction_id)
) ENGINE=InnoDB;

-- Staging table for USPTO 2023 annualized patent data
CREATE TABLE raw_uspto_2023 (
    patent_number            VARCHAR(20),
    grant_year               INT,
    application_number       VARCHAR(20),
    application_year         INT,
    d_inventor               INT,
    d_assignee               INT,
    d_location               INT,
    d_application            INT,
    d_cpc                    INT,
    d_ipc                    INT,
    d_wipo                   INT,
    assignee                 VARCHAR(255),
    assignee_sequence        INT,
    assignee_ind             INT,
    country                  VARCHAR(10),
    city                     VARCHAR(255),
    state                    VARCHAR(255),
    county                   VARCHAR(255),
    cpc_sections             VARCHAR(255),
    n_cpc                    INT,
    n_ipc                    INT,
    ipc_sections             VARCHAR(255),
    n_wipo                   INT,
    wipo_field_ids           VARCHAR(255),
    first_wipo_field_title   VARCHAR(255),
    first_wipo_sector_title  VARCHAR(255),
    team_size                INT,
    inventors                INT,
    men_inventors            INT,
    women_inventors          INT,
    inventor_id1             VARCHAR(50),
    inventor_name1           VARCHAR(255),
    male_flag1               TINYINT,
    inventor_id2             VARCHAR(50),
    inventor_name2           VARCHAR(255),
    male_flag2               TINYINT,
    inventor_id3             VARCHAR(50),
    inventor_name3           VARCHAR(255),
    male_flag3               TINYINT,
    inventor_id4             VARCHAR(50),
    inventor_name4           VARCHAR(255),
    male_flag4               TINYINT,
    inventor_id5             VARCHAR(50),
    inventor_name5           VARCHAR(255),
    male_flag5               TINYINT,
    inventor_id6             VARCHAR(50),
    inventor_name6           VARCHAR(255),
    male_flag6               TINYINT,
    inventor_id7             VARCHAR(50),
    inventor_name7           VARCHAR(255),
    male_flag7               TINYINT,
    inventor_id8             VARCHAR(50),
    inventor_name8           VARCHAR(255),
    male_flag8               TINYINT,
    inventor_id9             VARCHAR(50),
    inventor_name9           VARCHAR(255),
    male_flag9               TINYINT,
    inventor_id10            VARCHAR(50),
    inventor_name10          VARCHAR(255),
    male_flag10              TINYINT
);

