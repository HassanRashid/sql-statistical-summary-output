/* 
	Joining the products and transaction_id tables to get the **total sales per transaction**
*/

with transaction_totals as (
	select 	ti.transaction_id, 
			sum(p.price) as total_sales
	from transaction_items ti
	join products p
	on p.product_id = ti.product_id
	group by ti.transaction_id
)

/*
	Joining the transaction_totals table (CTE above) to the transactions table on transaction_id
	to also get the transaction date (trans_dt)
	Getting total_sales from the above table
	Getting the quartiles based on the total sales (per transaction)
	Output gives quartile integer for each of the transactions——but we want to get the specific quartile
	where the threshold/cutoff is at (25%, 50%, 75%). This is done in the CTE after this one
*/

, trans_sales as (
	select 	t.trans_dt,
			t.transaction_id,
			tt.total_sales,
			ntile(4) over(order by tt.total_sales asc) as quartile
	from transactions t
	join transaction_totals tt
	on tt.transaction_id = t.transaction_id
)

/*
	Getting the specific quartile where the threshold/cutoff is at (25%, 50%, 75%)
*/

, quartile_summary as (
	select
		ts.quartile, 						-- getting quartile value from the above CTE
		min(ts.total_sales)	as total_sales 	-- for each of the quartiles (which is the grouping), what is the
											-- minimum sale value or the threshold for each of the quartiles
	from trans_sales ts 					-- above CTE
	group by ts.quartile 					-- only shows quartile values 1, 2, 3, 4 (no repetition)
	order by ts.quartile asc
)

/*
	Getting the rest of the statistical summary output for total sales (avg, min, max)
*/

, total_sales_summary as (
	select
		avg(ts.total_sales) as avg_total_sales,
		max(ts.total_sales) as max_total_sales,
		min(ts.total_sales) as min_total_sales
	from trans_sales ts
);

select
	tss.avg_total_sales,
	tss.max_total_sales,
	tss.min_total_sales,
	max(case when qs.quartile = 1 then qs.total_sales else 0 end) as quartile_1_total_sales,
	/* 
		When the quartile is 1, assign the quartile 1 row that total_sales amount, and assign a 0 to quartile 2,3,4 rows
		We can take just the max from this to get the quartile 1 value because it is the only row that has the
		total_sales value, all the other rows (quartile 2, quartile 3, quartile 4) have 0 assigned to them
	*/
	max(case when qs.quartile = 2 then qs.total_sales else 0 end) as median_total_sales,
	max(case when qs.quartile = 3 then qs.total_sales else 0 end) as quartile_3_total_sales
from total_sales_summary tss, quartile_summary qs
group by tss.avg_total_sales, tss.max_total_sales, tss.min_total_sales;