/* ============================================================
   Mini-Project 2 — Advanced SQL Data Warehouse & Business Analytics
   Database : Superstore_DW1  (PostgreSQL)
   Dataset  : Central_Superstore.xlsx  (2,323 rows)
   Author   : Ahmed Mohamed Sayed
   ============================================================
   This script assumes the schema (staging + 5 dimension tables +
   1 fact table, with Primary/Foreign Keys already in place) has
   been created and loaded. Use pgAdmin's Backup tool on
   Superstore_DW1 (Format: Plain) to export the exact CREATE TABLE
   + INSERT statements as the schema/data record for submission.
   This file covers the ANALYTICAL layer: business queries, CTEs,
   view, stored procedure, function, and indexes.
   ============================================================ */


/* ------------------------------------------------------------
   SECTION 1 — Sanity checks (row counts per table)
   Purpose: confirm every table loaded correctly before analysis.
   ------------------------------------------------------------ */
SELECT 'dim_location'  AS table_name, COUNT(*) AS rows_count FROM public.dim_location
UNION ALL SELECT 'dim_ship_mode', COUNT(*) FROM public.dim_ship_mode
UNION ALL SELECT 'dim_product',   COUNT(*) FROM public.dim_product
UNION ALL SELECT 'dim_date',      COUNT(*) FROM public.dim_date
UNION ALL SELECT 'dim_customer',  COUNT(*) FROM public.dim_customer
UNION ALL SELECT 'fact_sales',    COUNT(*) FROM public.fact_sales;


/* ------------------------------------------------------------
   SECTION 2 — Core business analysis queries (10 queries)
   Each answers a specific business question for management.
   ------------------------------------------------------------ */

-- Q1. Quarterly sales, profit, and profit margin trend
-- Business question: "Is profitability improving or declining over time?"
SELECT
    d.orderyear,
    d.orderquarter,
    COUNT(DISTINCT f.orderid) AS total_orders,
    SUM(f.sales)  AS total_sales,
    SUM(f.profit) AS total_profit,
    ROUND((SUM(f.profit) / NULLIF(SUM(f.sales), 0)) * 100, 2) AS profit_margin_percentage
FROM public.fact_sales f
JOIN public.dim_date d ON f.orderdate = d.orderdate
GROUP BY d.orderyear, d.orderquarter
ORDER BY d.orderyear DESC, d.orderquarter DESC;


-- Q2. Profitability by category and sub-category
-- Business question: "Which product lines drive profit vs. which drag it down?"
SELECT
    p.category,
    p.sub_category,
    COUNT(f.orderid)   AS items_sold,
    SUM(f.sales)   AS category_sales,
    SUM(f.profit)  AS category_profit
FROM public.fact_sales f
JOIN public.dim_product p ON f.productid = p.product_id
GROUP BY p.category, p.sub_category
ORDER BY category_profit DESC;


-- Q3. Customer value tiering (CASE statement)
-- Business question: "Which customers are VIP and deserve retention focus?"
SELECT
    c.customerid,
    c.customername,
    c.segment,
    SUM(f.sales) AS total_spent,
    CASE
        WHEN SUM(f.sales) >= 10000 THEN 'VIP Customer'
        WHEN SUM(f.sales) BETWEEN 5000 AND 9999.99 THEN 'High Value'
        WHEN SUM(f.sales) BETWEEN 1000 AND 4999.99 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_tier
FROM public.fact_sales f
JOIN public.dim_customer c ON f.customerid = c.customerid
GROUP BY c.customerid, c.customername, c.segment
ORDER BY total_spent DESC;


-- Q4. Underperforming products (correlated subquery)
-- Business question: "Which products earn below the company-wide average profit?"
SELECT
    p.product_id,
    p.product_name,
    p.category,
    AVG(f.profit) AS avg_product_profit
FROM public.fact_sales f
JOIN public.dim_product p ON f.productid = p.product_id
GROUP BY p.product_id, p.product_name, p.category
HAVING AVG(f.profit) < (SELECT AVG(profit) FROM public.fact_sales)
ORDER BY avg_product_profit ASC;


-- Q5. Regional and state-level performance
-- Business question: "Where geographically should we focus sales investment?"
SELECT
    l.region,
    l.state,
    COUNT(DISTINCT f.orderid) AS total_orders,
    SUM(f.sales)  AS total_sales,
    SUM(f.profit) AS total_profit
FROM public.fact_sales f
JOIN public.dim_location l ON f.postalcode = l.postalcode
GROUP BY l.region, l.state
ORDER BY total_sales DESC;


-- Q6. High-value customers (CTE #1)
-- Business question: "List customers who generated over $5,000 in sales."
WITH CustomerSalesCTE AS (
    SELECT
        c.customerid,
        c.customername,
        c.segment,
        COUNT(f.orderid) AS total_orders,
        SUM(f.sales)  AS total_sales,
        SUM(f.profit) AS total_profit
    FROM public.fact_sales f
    JOIN public.dim_customer c ON f.customerid = c.customerid
    GROUP BY c.customerid, c.customername, c.segment
)
SELECT *
FROM CustomerSalesCTE
WHERE total_sales > 5000
ORDER BY total_sales DESC;


-- Q7. Product performance vs. category average (CTE #2 + CASE + JOIN)
-- Business question: "Which individual products beat their own category's average profit?"
WITH CategoryAvgProfitCTE AS (
    SELECT
        p.category,
        AVG(f.profit) AS avg_category_profit
    FROM public.fact_sales f
    JOIN public.dim_product p ON f.productid = p.product_id
    GROUP BY p.category
)
SELECT
    p.product_id,
    p.product_name,
    p.category,
    SUM(f.profit) AS total_product_profit,
    c.avg_category_profit,
    CASE
        WHEN SUM(f.profit) > c.avg_category_profit THEN 'Above Average'
        ELSE 'Below Average'
    END AS performance_status
FROM public.fact_sales f
JOIN public.dim_product p ON f.productid = p.product_id
JOIN CategoryAvgProfitCTE c ON p.category = c.category
GROUP BY p.product_id, p.product_name, p.category, c.avg_category_profit
ORDER BY p.category, total_product_profit DESC;


-- Q8. Discount tier impact on profitability (CASE)
-- Business question: "Is heavy discounting actually hurting profit?"
SELECT
    CASE
        WHEN discount = 0 THEN 'No Discount (0%)'
        WHEN discount > 0 AND discount <= 0.20 THEN 'Low Discount (1-20%)'
        WHEN discount > 0.20 AND discount <= 0.50 THEN 'Medium Discount (21-50%)'
        ELSE 'High Discount (>50%)'
    END AS discount_tier,
    COUNT(orderid) AS total_orders,
    SUM(sales)  AS total_sales,
    SUM(profit) AS total_profit,
    AVG(profit) AS avg_profit_per_order
FROM public.fact_sales
GROUP BY discount_tier
ORDER BY total_profit DESC;


-- Q9. Top 5 cities per region by sales (window function)
-- Business question: "Who are the best-performing cities within each region?"
SELECT *
FROM (
    SELECT
        l.region,
        l.city,
        SUM(f.sales)  AS total_sales,
        SUM(f.profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY l.region ORDER BY SUM(f.sales) DESC) AS rank_in_region
    FROM public.fact_sales f
    JOIN public.dim_location l ON f.postalcode = l.postalcode
    GROUP BY l.region, l.city
) ranked_cities
WHERE rank_in_region <= 5;


-- Q10. Segment contribution to total company profit (subquery)
-- Business question: "Which customer segment contributes most to overall profit?"
SELECT
    c.segment,
    SUM(f.sales)  AS segment_sales,
    SUM(f.profit) AS segment_profit,
    ROUND((SUM(f.profit) / (SELECT SUM(profit) FROM public.fact_sales)) * 100, 2) AS profit_contribution_pct
FROM public.fact_sales f
JOIN public.dim_customer c ON f.customerid = c.customerid
GROUP BY c.segment
ORDER BY segment_profit DESC;


-- Q11. Shipping method mix and its link to profitability
-- Business question: "Do faster (more expensive) shipping modes affect profit margin?"
SELECT
    sm.ship_mode,
    COUNT(f.orderid) AS total_orders,
    SUM(f.sales)  AS total_sales,
    SUM(f.profit) AS total_profit,
    ROUND((SUM(f.profit) / NULLIF(SUM(f.sales), 0)) * 100, 2) AS profit_margin_pct
FROM public.fact_sales f
JOIN public.dim_ship_mode sm ON f.ship_mode_key = sm.ship_mode_key
GROUP BY sm.ship_mode
ORDER BY total_sales DESC;


/* ------------------------------------------------------------
   SECTION 3 — Reusable objects (View, Procedure, Function)
   ------------------------------------------------------------ */

-- View: monthly KPI summary — reusable dashboard-style query
CREATE OR REPLACE VIEW public.vw_monthly_kpi_summary AS
SELECT
    d.orderyear,
    d.ordermonth,
    COUNT(DISTINCT f.orderid)   AS total_orders,
    COUNT(DISTINCT f.customerid) AS unique_customers,
    SUM(f.sales)  AS total_sales,
    SUM(f.profit) AS total_profit,
    ROUND((SUM(f.profit) / NULLIF(SUM(f.sales), 0)) * 100, 2) AS profit_margin_pct
FROM public.fact_sales f
JOIN public.dim_date d ON f.orderdate = d.orderdate
GROUP BY d.orderyear, d.ordermonth;

SELECT * FROM public.vw_monthly_kpi_summary ORDER BY orderyear DESC, ordermonth DESC;


-- Stored Procedure: computes real KPIs for a given region
CREATE OR REPLACE PROCEDURE public.sp_get_regional_performance(p_region VARCHAR)
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_orders BIGINT;
    v_total_sales  NUMERIC;
    v_total_profit NUMERIC;
    v_avg_discount NUMERIC;
BEGIN
    SELECT
        COUNT(DISTINCT f.orderid), SUM(f.sales), SUM(f.profit), AVG(f.discount)
    INTO v_total_orders, v_total_sales, v_total_profit, v_avg_discount
    FROM public.fact_sales f
    JOIN public.dim_location l ON f.postalcode = l.postalcode
    WHERE LOWER(l.region) = LOWER(p_region);

    IF v_total_orders IS NULL OR v_total_orders = 0 THEN
        RAISE NOTICE 'No data found for region: %', p_region;
    ELSE
        RAISE NOTICE 'Region: % | Orders: % | Sales: % | Profit: % | Avg Discount: %',
            p_region, v_total_orders, ROUND(v_total_sales, 2),
            ROUND(v_total_profit, 2), ROUND(v_avg_discount, 4);
    END IF;
END;
$$;

CALL public.sp_get_regional_performance('Central');


-- Function: returns a result set of city-level sales for a given region
CREATE OR REPLACE FUNCTION public.fn_get_regional_sales(p_region VARCHAR)
RETURNS TABLE (
    city VARCHAR,
    total_sales NUMERIC,
    total_profit NUMERIC,
    orders_count BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        l.city,
        SUM(f.sales)  AS total_sales,
        SUM(f.profit) AS total_profit,
        COUNT(DISTINCT f.orderid) AS orders_count
    FROM public.fact_sales f
    JOIN public.dim_location l ON f.postalcode = l.postalcode
    WHERE LOWER(l.region) = LOWER(p_region)
    GROUP BY l.city
    ORDER BY total_sales DESC;
END;
$$;

SELECT * FROM public.fn_get_regional_sales('Central');


/* ------------------------------------------------------------
   SECTION 4 — Performance optimization (indexes)
   ------------------------------------------------------------ */
CREATE INDEX IF NOT EXISTS idx_fact_sales_orderdate   ON public.fact_sales(orderdate);
CREATE INDEX IF NOT EXISTS idx_fact_sales_customerid  ON public.fact_sales(customerid);
CREATE INDEX IF NOT EXISTS idx_fact_sales_productid   ON public.fact_sales(productid);
CREATE INDEX IF NOT EXISTS idx_fact_sales_postalcode  ON public.fact_sales(postalcode);
CREATE INDEX IF NOT EXISTS idx_fact_sales_shipmodekey ON public.fact_sales(ship_mode_key);
CREATE INDEX IF NOT EXISTS idx_dim_product_category   ON public.dim_product(category);
CREATE INDEX IF NOT EXISTS idx_dim_location_region    ON public.dim_location(region);


/* ------------------------------------------------------------
   SECTION 5 — Data quality validation (final checks)
   ------------------------------------------------------------ */
-- fact_sales row count must equal stg_superstore row count (2,323)
SELECT
    (SELECT COUNT(*) FROM public.stg_superstore) AS staging_rows,
    (SELECT COUNT(*) FROM public.fact_sales)     AS fact_rows,
    (SELECT COUNT(*) FROM public.fact_sales WHERE ship_mode_key IS NULL) AS missing_ship_mode;
