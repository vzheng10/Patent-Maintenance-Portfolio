# Patent Maintenance Portfolio Analytics 
**A MySQL-based data modeling and analytics project using real United States Patent and Trademark Office (USPTO) 2023 granted patent data.**  
This project demonstrates relational database design, data normalization, and portfolio-style analytics for patent maintenance fee forecasting and expiry tracking.

---

## Overview
This project models a simplified patent portfolio management system.  
It focuses on transforming raw USPTO data into a normalized relational schema and generating analytics around patent maintenance deadlines and fees.

### Features
- **Normalized database schema** for clients, jurisdictions, patents, deadlines, and maintenance costs  
- **ETL pipeline** that loads raw USPTO CSV data into a staging table and populates normalized tables  
- **Analytics queries** to calculate maintenance-fee schedules, expected revenue by year, and expiring patents  
- Demonstrates **SQL design patterns** such as `JOIN`, `GROUP BY`, and `COALESCE` for data cleaning and reporting  

---

## Project Structure

### **Main Files**
| File | Description |
|------|--------------|
| **`schema.sql`** | Defines the full database schema. Creates normalized tables for `clients`, `jurisdictions`, `patents`, `deadlines`, and `costs`, along with a staging table `raw_uspto_2023`. Establishes keys, relationships, and constraints. |
| **`populate.sql`** | Implements the data pipeline that populates normalized tables from the raw USPTO dataset. Generates deadlines (3, 7, and 11 years post-grant) and estimated maintenance costs for each patent. |
| **`queries_demo.sql`** | Contains showcase SQL queries that demonstrate the schema’s analytical capabilities — such as maintenance schedules, total expected revenue by jurisdiction, and patents approaching expiry. |

---

### **Data Files**
| File | Description |
|------|--------------|
| **`USPTO 2023 Clean.csv`** | Cleaned version of the USPTO granted patent dataset used for the project. Loaded directly into the staging table `raw_uspto_2023`. |

---

## Database Design

### **Schema Overview**
- **`clients`** – patent owners (assignees)  
- **`jurisdictions`** – patent offices or country codes (e.g., US, JP, DE)  
- **`patents`** – one record per granted patent, linked to clients and jurisdictions  
- **`deadlines`** – models maintenance-fee events (3, 7, and 11 years from grant)  
- **`costs`** – estimated maintenance fees in USD, linked to deadlines and jurisdictions  

### **Data Flow**
1. Load raw USPTO CSV into the `raw_uspto_2023` staging table.  
2. Populate lookup tables (`clients`, `jurisdictions`) from distinct values.  
3. De-duplicate and populate `patents` with key details (filing/grant year, client, jurisdiction).  
4. Auto-generate `deadlines` and `costs` for maintenance-fee forecasting.  

---

## Example Analytics Queries
| Query | Purpose |
|--------|----------|
| **Row counts & sanity checks** | Validate table populations and relationships. |
| **Maintenance schedule per patent** | Joins patents and deadlines to display upcoming 3-, 7-, and 11-year maintenance events. |
| **Total expected maintenance revenue by year/jurisdiction** | Aggregates costs to forecast portfolio-level revenue. |
| **Patents approaching expiry** | Lists patents whose (filing_year + 20) falls within a given window (e.g., 2025–2030). |
