# Patent Maintenance Portfolio Analytics (MySQL)

This project models a simplified **patent portfolio management system** using real **United States Patent and Trademark Office (USPTO) 2023 granted patent data**. It focuses on:

- Normalizing raw USPTO patent data into a relational schema  
- Tracking **maintenance-fee deadlines** for granted patents  
- Forecasting **expected maintenance fees by year and jurisdiction**  
- Identifying patents approaching **expiry** (assuming a 20-year term from filing year)

The project is organized into three main SQL files:

- `schema.sql` – defines the database structure  
- `populate.sql` – implements the data pipeline from raw USPTO data  
- `queries_demo.sql` – contains showcase analytics queries

---

## Files in This Project

### `schema.sql`

Defines the full database schema for the project and creates the database:

- Creates the `ip_management` database and sets it as the active schema.
- Creates normalized tables:
  - `clients` – patent owners (assignees)
  - `jurisdictions` – patent office / country codes  
    - In this project, `name` is stored the same as `code` because the USPTO dataset only provides codes (e.g. `US`, `JP`, `DE`).
  - `patents` – one row per patent, linked to `clients` and `jurisdictions`  
    - Uses `filing_year` and `grant_year` (year-level only).  
    - `status` is set to `'Granted'` for all records, since the source dataset contains granted patents.
  - `deadlines` – patent maintenance-fee deadlines  
    - Models only 3-year, 7-year, and 11-year maintenance events as year offsets from `grant_year`.
  - `costs` – monetary amounts associated with those maintenance deadlines  
    - Stores fee amounts (USD), jurisdiction, and the `due_year` for aggregation.
- Creates a staging table:
  - `raw_uspto_2023` – direct load of the USPTO 2023 annualized granted patents CSV.

### `populate.sql`

Implements the **data pipeline** that moves data from the raw staging table into the normalized schema.

It:

1. **Assumes** `raw_uspto_2023` has already been populated from the USPTO CSV.
2. Populates lookup tables:
   - `jurisdictions` from distinct `country` values in `raw_uspto_2023`
   - `clients` from distinct `assignee` values
3. Populates `patents`:
   - De-duplicates by `patent_number` so there is exactly one row per patent.
   - Uses a `GROUP BY patent_number` inner query and `MAX()` aggregates to collapse multiple rows into one per patent.
   - Joins to `clients` and `jurisdictions` to set foreign keys.
   - Sets `filing_year` and `grant_year` from the USPTO data, and `status = 'Granted'`.
4. Generates `deadlines`:
   - Creates 3-year, 7-year, and 11-year maintenance-fee deadlines for each patent:
     - `due_year = grant_year + 3`
     - `due_year = grant_year + 7`
     - `due_year = grant_year + 11`
   - Stores one row per patent per maintenance event.
5. Generates `costs`:
   - For each maintenance deadline, inserts a row into `costs` with:
     - `fee_type = 'maintenance'`
     - A fee amount approximating USPTO maintenance fees (e.g. 2,150 / 4,040 / 8,280 USD)
     - The corresponding `due_year` and `jurisdiction_id`.

The file also contains an **optional, commented-out** block for resetting tables during development (truncating normalized tables and re-running the pipeline).

### `queries_demo.sql`

Contains **showcase queries** that demonstrate how the schema supports patent portfolio analytics:

- Sanity checks:
  - Row counts for `patents`, `deadlines`, and `costs`.
  - Distribution of `deadline_type` values in `deadlines`.
- **Maintenance fee schedule per patent**:
  - Joins `patents` and `deadlines` to show, for each patent, its 3-year, 7-year, and 11-year maintenance-fee years.
- **Total expected maintenance revenue by year & jurisdiction**:
  - Aggregates `costs` by `due_year` and jurisdiction.  
  - Uses `COALESCE(NULLIF(j.name, ''), 'Unknown')` to label missing or blank jurisdictions as `"Unknown"`.
- **Patents approaching expiry**:
  - Assumes a 20-year term from `filing_year`.
  - Lists patents whose `(filing_year + 20)` falls within a specified window (e.g. 2025–2030), along with client and jurisdiction.

These queries are intended to be the “demo layer” you walk through in an interview to show how the model supports real portfolio questions.

---

## Data
- **Source:** USPTO 2023 annualized granted patent data.
- **Cleaned CSV in this repo:** `USPTO 2023 Clean.csv`
- This CSV is loaded directly into the `raw_uspto_2023` staging table defined in `schema.sql`.
