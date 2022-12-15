set search_path=public;
-- Which ship mode is preferred by customers?

select ship_mode,count(DISTINCT (order_id)) from public."Orders"
group by ship_mode
order by 2 desc;

-- Which region/state has highest sales?

select * from (
with q1 as (
select g."state/province", g."city", sum(o."sales")
from public."Orders" o
JOIN public."geo" g on o."postal_code" = g."PostalCode"
group by 1,2
)
select q1."state/province",q1."city",
rank() over (partition by q1."state/province" order by q1."sum")
from q1) as q2
where rank <= 5;

-- Which category has highest sales?

select p."category", sum(o."sales")
from public."Orders" o
JOIN public."products" p on o."product_id" = p."id"
group by 1
order by 2 desc;

-- Sales by year

select extract( year from o."order_date"),sum(o."sales") 
from public."Orders" o
group by 1
order by 2 desc;

-- Find out 1 month moving average of sales for each year
CREATE VIEW monthly_moving_average AS (
with q1 as (
select extract( year from o."order_date") as year,extract( month from o."order_date") as month_no,TO_CHAR(o."order_date",'month') as month,sum(o."sales") as sales
from public."Orders" o
group by 1,2,3
order by 1,2)

select q1."year", q1."month", q1."sales",
avg(q1."sales") over (partition by year order by q1."month_no" ROWS BETWEEN 1 PRECEDING AND CURRENT ROW) AS Mvg_Avg
from q1)

-- Which region has maximum profit in each year?
CREATE VIEW profit_each_year AS (
with q2 as (
with q1 as (
select extract( year from o."order_date") as year,r."region", sum(o."profit") as profit
from public."Orders" o
JOIN public."geo" g on o."postal_code" = g."PostalCode"
JOIN public."region" r on g."region" = r."regionId"
group by 1,2
order by 1)
Select q1.year, q1.region,q1.profit,
rank() over (partition by q1.year order by q1.profit desc)
from q1)
select q2.year,q2.region,q2.profit from q2
where q2.rank = 1);

-- Count all the products that have a profit > average profit within their category
with q1 as (
select p.category,p.productname,o.profit,
avg(o.profit) over (partition by p.category)
from 
public."Orders" o
join public.products p 
ON o.product_id = p.id)
select q1.category,count(productname)
from q1
where q1.profit>q1.avg
group by 1;


-- Find the difference between ship date and order date for each order?

select o.order_id,o.order_date,o.ship_date,date_part('day',o.ship_date)-date_part('day',o.order_date) as no_of_days
from public."Orders" o;

-- Find % growth in sales for each year/month?
CREATE VIEW percentage_sales_growth as (
with q1 as (

select extract( year from o."order_date") as year,extract( month from o."order_date") as month_no,TO_CHAR(o."order_date",'month') as month,sum(o."sales") as sales
from public."Orders" o
group by 1,2,3
order by 1,2
)
select q1.year,q1.month,q1.sales as current_sales,
LAG(q1.sales) over (partition by q1.year order by q1.month_no) as previous_sales,
(q1.sales - LAG(q1.sales) over (partition by q1.year order by q1.month_no))/(q1.sales + LAG(q1.sales) over (partition by q1.year order by q1.month_no)) as percentage_growth
from q1);


