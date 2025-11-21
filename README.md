# Patent Maintenance Portfolio Analytics (MySQL)
This project models a simplified **patent portfolio management system** using real **USPTO 2023 granted patent data**.

It focuses on:
- Normalizing raw USPTO patent data into a relational schema  
- Tracking **maintenance fee deadlines** for granted patents  
- Forecasting **expected maintenance fees by year and jurisdiction**

The goal is to simulate the kind of backend data model and queries that an IP management platform might use for **patent maintenance only** (no trademarks).

---

## 🔎 Project Overview

**Objective**

Start from the USPTO annualized patent dataset and build a MySQL database that can answer questions like:

- Which patents belong to which **client** (assignee) and **jurisdiction** (country)?
- When are **maintenance fees** due for each patent?
- What are the **total maintenance fees** expected per year and per jurisdiction?
- Which patents are approaching **expiry**, assuming a 20-year term from filing year?

**Key Design Choices**

- Use `raw_uspto_2023` as a **staging table** for the original CSV.
- Normalize the data into:
  - `clients` – patent owners (assignees)
  - `jurisdictions` – patent country codes
  - `patents` – one row per patent (de-duplicated by `patent_number`)
  - `deadlines` – year-level maintenance fee deadlines
  - `costs` – maintenance fee amounts tied to those deadlines
- Model time at the **year level** (`filing_year`, `grant_year`, `due_year`) since the USPTO dataset provides year, not exact dates.

---

## 🧱 Core Tables (Summary)

- **`raw_uspto_2023`** – USPTO staging table (as imported from CSV)
- **`clients`** – distinct assignees
- **`jurisdictions`** – distinct country codes from the data
- **`patents`**
  - Links each patent to a client and jurisdiction
  - Stores `patent_number`, `title`, `filing_year`, `grant_year`, `status`
- **`deadlines`**
  - One row per patent per maintenance event (3, 7, 11 years after grant)
- **`costs`**
  - One row per patent per maintenance event, storing fee **amount** and **due_year**

---

## 📊 Example Analytics

- **Maintenance schedule per patent**
- **Total expected maintenance fees by year and jurisdiction**
- **Patents approaching expiry (20-year life from filing year)**

See the SQL scripts in this repo for the full schema, data-loading pipeline, and example queries.
