CREATE OR REPLACE PROCEDURE public.sp_get_regional_performance(p_region VARCHAR)
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_orders   BIGINT;
    v_total_sales    NUMERIC;
    v_total_profit   NUMERIC;
    v_avg_discount   NUMERIC;
BEGIN
    SELECT 
        COUNT(DISTINCT f.orderid),
        SUM(f.sales),
        SUM(f.profit),
        AVG(f.discount)
    INTO 
        v_total_orders,
        v_total_sales,
        v_total_profit,
        v_avg_discount
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