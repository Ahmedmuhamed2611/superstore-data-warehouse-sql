# Central Superstore Data Warehouse 🛒

## Project Overview
This project transforms raw operational retail data from the Central Superstore dataset into a highly structured, analytical data warehouse. Built using SQL Server and PostgreSQL, the architecture establishes a robust and scalable foundation for business intelligence and automated reporting.

**Final Grade:** 100/100 🏆

---

## Database Architecture: The Star Schema
The raw data was processed and normalized into a **Star Schema** to optimize read operations and complex aggregations:
* **1 Fact Table:** Centralizes transactional records and quantitative metrics (orders, sales quantities, profit margins).
* **4 Dimension Tables:** Stores descriptive attributes categorized into:
  * Customer Dimension
  * Product Dimension
  * Geography/Location Dimension
  * Time/Date Dimension

---

## Technical Implementation & Advanced Queries
The analytical engine is powered by **15 advanced SQL queries** designed to extract deep strategic insights, featuring:
* **Complex JOIN Operations:** Reconnecting the star schema to generate comprehensive reports across product hierarchies and regional performance.
* **Common Table Expressions (CTEs):** Modularizing multi-step analytical logic such as running totals, moving averages, and customer tier rankings.
* **SQL Views:** Dedicated virtual tables abstracting schema complexity for instant KPI monitoring (Total Revenue, Average Order Value, Profit Margins).
* **Stored Procedures:** Reusable, parameterized server-side routines automating specific business logic and data transformations.

---

## Repository Structure
* `01_schema_creation.sql`: DDL scripts for building the star schema, defining relationships, and setting primary/foreign keys.
* `02_advanced_queries.sql`: The 15 core analytical queries utilizing CTEs and complex JOINs.
* `03_programmability.sql`: Scripts defining the KPI View and Stored Procedures.
* 
