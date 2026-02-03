-- Monday Coffee SCHEMAS

DROP TABLE IF EXISTS sales;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS city;


CREATE TABLE city
(
	city_id	INT PRIMARY KEY,
	city_name VARCHAR(15),	
	population	BIGINT,
	estimated_rent	FLOAT,
	city_rank INT
);

CREATE TABLE customers
(
	customer_id INT PRIMARY KEY,	
	customer_name VARCHAR(25),	
	city_id INT,
	CONSTRAINT fk_city FOREIGN KEY (city_id) REFERENCES city(city_id)
);


CREATE TABLE products
(
	product_id	INT PRIMARY KEY,
	product_name VARCHAR(35),	
	Price float
);


CREATE TABLE sales
(
	sale_id	INT PRIMARY KEY,
	sale_date	date,
	product_id	INT,
	customer_id	INT,
	total FLOAT,
	rating INT,
	CONSTRAINT fk_products FOREIGN KEY (product_id) REFERENCES products(product_id),
	CONSTRAINT fk_customers FOREIGN KEY (customer_id) REFERENCES customers(customer_id) 
);

-- END of SCHEMAS
select * from sales
select * from products
select * from customers
select * from city

--Business Problems

--Coffee Consumers Count
--1.How many people in each city are estimated to consume coffee, given that 25% of the population does?
select city_name,
round((population*0.25)/1000000,2) as consumer_in_millions,
city_rank
from city
order by 2 desc


--Total Revenue from Coffee Sales
--2.What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?
select *,
extract(year from sale_date) as year,
extract(quarter from sale_date) as quarter
from sales
where 
  extract(year from sale_date)='2023'
  and
  extract(quarter from sale_date)='4'



select
ci.city_name,
sum(s.total) as total_revenue
from sales as s
join customers as c
on s.customer_id=c.customer_id
join city as ci
on c.city_id=ci.city_id
where 
  extract(year from sale_date)='2023'
  and
  extract(quarter from sale_date)='4'
  group by 1
  order by 2 desc


--Sales Count for Each Product
--3.How many units of each coffee product have been sold?
select 
 p.product_name,
 count(s.sale_id) as total_orders
from products as p
left join sales as s
on s.product_id=p.product_id
group by 1
order by 2 desc


--Average Sales Amount per City
--4.What is the average sales amount per customer in each city?
select 
 ci.city_name,
 sum(s.total) as total_revenue,
 count(distinct c.customer_name) as total_customers,
 round(
 sum(s.total)::numeric /count(distinct c.customer_name)::numeric,2) as avg_sales_amount
 
from sales as s
join customers as c
on s.customer_id=c.customer_id
join city as ci
on c.city_id=ci.city_id
group by 1
order by 2 desc


--City Population and Coffee Consumers
--5.Provide a list of cities along with their populations and estimated coffee consumers.
WITH city_table as 
(
	SELECT 
		city_name,
		ROUND((population * 0.25)/1000000, 2) as coffee_consumers
	FROM city
),
customers_table
AS
(
	SELECT 
		ci.city_name,
		COUNT(DISTINCT c.customer_id) as unique_cx
	FROM sales as s
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
)
SELECT 
	customers_table.city_name,
	city_table.coffee_consumers as coffee_consumer_in_millions,
	customers_table.unique_cx
FROM city_table
JOIN 
customers_table
ON city_table.city_name = customers_table.city_name


--Top Selling Products by City
--6.What are the top 3 selling products in each city based on sales volume?
select * from
(
select 
 p.product_name,
 ci.city_name,
 count(s.sale_id) as total_orders,
 dense_rank() over (partition by ci.city_name order by count(s.sale_id)desc ) as rank
from products as p
join sales as s
on p.product_id=s.product_id
join customers as c
on s.customer_id=c.customer_id
join city as ci
on c.city_id=ci.city_id
group by 1,2
) as t1
where rank<=3

--Customer Segmentation by City
--7.How many unique customers are there in each city who have purchased coffee products?
select 
 ci.city_name,
 count(distinct c.customer_id) as unique_cx
from sales as s
join customers as c
on s.customer_id=c.customer_id
join city as ci
on c.city_id=ci.city_id
where
  s.product_id in (1,2,3,4,5,6,7,8,9,10,11,12,13,14)
group by 1
order by 2 desc

--Average Sale vs Rent
--Find each city and their average sale per customer and avg rent per customer
WITH city_table
AS
(
SELECT 
 ci.city_name,
	SUM(s.total) as total_revenue,
	COUNT(DISTINCT s.customer_id) as total_cx,
	ROUND(
		SUM(s.total)::numeric/
			COUNT(DISTINCT s.customer_id)::numeric,2) as avg_sale_pr_cx
		
	FROM sales as s
	JOIN customers as c
	ON s.customer_id = c.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
	ORDER BY 2 DESC
),
city_rent
AS
(SELECT 
	city_name, 
	estimated_rent
FROM city
)
SELECT 
	cr.city_name,
	cr.estimated_rent,
	ct.total_cx,
	ct.avg_sale_pr_cx,
	ROUND(
		cr.estimated_rent::numeric/ct.total_cx::numeric, 2) as avg_rent_per_cx
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 4 DESC


--Monthly Sales Growth
--9.Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly) by each city.
with city_table 
as
(
select 
 ci.city_name,
 extract(month from s.sale_date) as month,
 extract(year from s.sale_date) as year,
 sum(s.total) as total_sales
 FROM sales as s
	JOIN customers as c
	ON s.customer_id = c.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
group by 1, 2, 3
order by 1,3,2),
growth_ratioo
as
(
select
 city_name,
 month,
 year,
 total_sales as cr_month_sale,
 lag(total_sales,1) over(partition by city_name order by year,month) as last_month_sale
 from city_table
 )
 select 
 city_name,
 month,
 year,
 cr_month_sale,
 last_month_sale,
 round((cr_month_sale -  last_month_sale)::numeric/last_month_sale::numeric*100 ,2)as growth_ratio
 from growth_ratioo
  where 
    last_month_sale is not null


--Market Potential Analysis
--10.Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers,
---estimated coffee consumer,average rent and average sales per customer
WITH city_table
AS
(
	SELECT 
		ci.city_name,
		SUM(s.total) as total_revenue,
		COUNT(DISTINCT s.customer_id) as total_cx,
		ROUND(SUM(s.total)::numeric/COUNT(DISTINCT s.customer_id)::numeric,2) as avg_sale_pr_cx
	FROM sales as s
	JOIN customers as c
	ON s.customer_id = c.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
	ORDER BY 2 DESC
),
city_rent
AS
(
	SELECT 
		city_name, 
		estimated_rent,
		ROUND((population * 0.25)/1000000, 3) as estimated_coffee_consumer_in_millions
	FROM city
)
SELECT 
	cr.city_name,
	total_revenue,
	cr.estimated_rent as total_rent,
	ct.total_cx,
	estimated_coffee_consumer_in_millions,
	ct.avg_sale_pr_cx,
	ROUND(cr.estimated_rent::numeric/ct.total_cx::numeric, 2) as avg_rent_per_cx
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 2 DESC

/*
 Recommendation
 City 1: Pune
	1.Average rent per customer is very low.
	2.Highest total revenue.
	3.Average sales per customer is also high.

City 2: Delhi
	1.Highest estimated coffee consumers at 7.7 million.
	2.Highest total number of customers, which is 68.
	3.Average rent per customer is 330 (still under 500).

City 3: Jaipur
	1.Highest number of customers, which is 69.
	2.Average rent per customer is very low at 156.
	3.Average sales per customer is better at 11.6k.





	



