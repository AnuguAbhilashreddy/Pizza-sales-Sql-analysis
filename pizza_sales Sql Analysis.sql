-- Q.1 Total Orders
select Count(order_id)  no_of_orders_placed from orders;

-- Q.2 total Quantity
select sum(quantity) as total_Quantity from order_details;

-- Q.3 total Revenue
select concat(round(Sum(Quantity*price)/1000000,2) ," M") as Revenue from order_details od join pizzas p
on p.pizza_id =od.pizza_id;

--  Q4.avg order value

with order_summary as (
  select 
    count(distinct o.order_id) as total_orders,
    round(sum(od.quantity * p.price), 2) as total_revenue
  from order_details od
  join pizzas p on p.pizza_id = od.pizza_id
  join orders o on o.order_id = od.order_id
)
select 
  round(total_revenue / total_orders, 2) as avg_order_value 
from order_summary;

-- Q5(i). highest pizza price 
select p.pizza_type_id,name,size,price from pizzas p
join pizza_types pt 
on pt.pizza_type_id=p.pizza_type_id
where price=(select max(price) from pizzas);



-- Q5(ii). least Pizza Price 
SELECT 
    p.pizza_type_id, name, size, price
FROM
    pizzas p
        JOIN
    pizza_types pt ON pt.pizza_type_id = p.pizza_type_id
WHERE
    price = (SELECT 
            MIN(price)
        FROM
            pizzas);

-- Q6. highest order value
  with order_amount as 
	(select 
    order_id,
    round(sum(od.quantity * p.price), 2) as total_revenue
  from order_details od
  join pizzas p on p.pizza_id = od.pizza_id
  group by order_id
  order by total_revenue desc
  )
    select order_id,total_revenue from order_amount
  where total_revenue=(select max(total_revenue) from order_amount);
  
  
-- Q7 least order value

 with order_amount as 
	(select 
    
    round(sum(od.quantity * p.price), 2) as total_revenue
  from order_details od
  join pizzas p on p.pizza_id = od.pizza_id
  group by order_id
  order by total_revenue desc
  )
    select distinct total_revenue from order_amount
  where total_revenue=(select min(total_revenue) from order_amount);
  

-- Q8. pizza size wise sales
SELECT 
    Size AS Pizza_size,
    SUM(quantity) AS sold_quantity,
    ROUND(SUM(Quantity * price), 2) AS total_sales
FROM
    order_details od
        JOIN
    pizzas p ON p.pizza_id = od.pizza_id
GROUP BY 1;

-- Q9. Monthly Sales

select monthname(o.order_date) as Month_,
                round(Sum(Quantity*price),2) as total_sales
                from order_details od join pizzas p
on p.pizza_id =od.pizza_id
join orders O
on o.order_id=od.order_id
group by 1;

-- Q10. monthly sales growth rate
with monthly_sales as (
				select concat(monthname(o.order_date),"-",year(o.order_date)) as Month_year,
                concat(round(Sum(Quantity*price)/1000000,2)," M") as total_sales
                from order_details od join pizzas p
on p.pizza_id =od.pizza_id
join orders O
on o.order_id=od.order_id
group by 1)
select Month_year,
		total_sales as month_sales,
       ifnull( lag(total_sales) over(),"-") as Previous_month_sales,
      ifnull(concat(round((total_sales-lag(total_sales) over())*100/lag(total_sales) over() ,2),"%"),"-") as monthly_growth
        
from monthly_sales;

-- Q11. highest od lowest months on revenue
with Monthly_sales as (select monthname(o.order_date) as Month_,
                round(Sum(Quantity*price)/1000000,3) as revenue
                from order_details od join pizzas p
on p.pizza_id =od.pizza_id
join orders O
on o.order_id=od.order_id
group by 1)
select month_,revenue as Min_Max_sales from Monthly_sales
where revenue= (select min(revenue) from monthly_sales )
or
revenue= ( select max(revenue) from Monthly_sales
)
;

-- Q12. which day has highest sales

select dayname(o.order_date) as day_,count(o.order_id) as orders,
                round(Sum(Quantity*price),2) as total_sales
                from order_details od join pizzas p
on p.pizza_id =od.pizza_id
join orders O
on o.order_id=od.order_id
group by 1
order by 2 desc;

-- Q13. time analysis

select  CONCAT(LPAD(HOUR(order_time), 2, '0'), '-', LPAD(HOUR(order_time)+1, 2, '0')) as time_,
count(o.order_id) as total_orders,
                round(Sum(Quantity*price),2) as total_sales
                from order_details od join pizzas p
on p.pizza_id =od.pizza_id
join orders O
on o.order_id=od.order_id
group by 1
order by 2 desc;

 -- Q14. Top selling pizzas in each month 

with pizza_sales as (select monthname(order_date) as month_, 
						Name, 
						sum(Quantity) as sold_quantity
                        from pizzas P
						join order_details  od
						on od.pizza_id= p.pizza_id 
						join orders O 
						on o.order_id=od.order_id
                        join pizza_types pt
                        on pt.pizza_type_id = p.pizza_type_id
						group by 1,name
					),
rank_orders as (select * ,
				rank() over (partition by month_ order by sold_quantity desc) as rn 
                from pizza_sales
                )
select month_ as Month_name,name as Pizza_types,sold_quantity from rank_orders
where rn=1;


-- Q15. pizza types analysis

SELECT 
    name,
    SUM(quantity) AS Quantity,
    SUM(Quantity * price) AS Revenue
FROM
    pizzas P
        JOIN
    order_details od ON od.pizza_id = p.pizza_id
        JOIN
    pizza_types pt ON pt.pizza_type_id = p.pizza_type_id
GROUP BY name
;

-- Q16. pizza sales by category
SELECT 
    category,
    COUNT(order_id) AS
    orders,
	sum(Quantity) as Sold_quantity,
    concat(ROUND(SUM(price * Quantity)/1000000, 2)," M") AS revenue
FROM
    pizzas P
        JOIN
    order_details od ON od.pizza_id = p.pizza_id
        JOIN
    pizza_types pt ON pt.pizza_type_id = p.pizza_type_id
GROUP BY category
;
-- Q17. revenue pct contibution by category

with Revenue_by_category as (SELECT 
    category,
    ROUND(SUM(price * Quantity), 2) AS revenue
FROM
    pizzas P
        JOIN
    order_details od ON od.pizza_id = p.pizza_id
        JOIN
    pizza_types pt ON pt.pizza_type_id = p.pizza_type_id
GROUP BY category)
select category,
		revenue,
        sum(revenue) over() as total_revenue,
        round((revenue*100/sum(revenue) over()),2) as pct_revenue 
        from Revenue_by_category
;

-- Q18. avg order value by category
SELECT 
    category,
   ROUND(SUM(price * Quantity)/COUNT(order_id) , 2) AOV_category
FROM
    pizzas P
        JOIN
    order_details od ON od.pizza_id = p.pizza_id
        JOIN
    pizza_types pt ON pt.pizza_type_id = p.pizza_type_id
GROUP BY category
;

-- Q19. Top 3  selling pizzas by category 

with most_selling_pizza as (
	SELECT 
    category,
    name,
     sum(quantity) as total_quantity,
    ROUND(SUM(price * Quantity), 2) AS revenue
FROM
    pizzas P
        JOIN
    order_details od ON od.pizza_id = p.pizza_id
        JOIN
    pizza_types pt ON pt.pizza_type_id = p.pizza_type_id
GROUP BY category,name
),
ranking as (select *,
dense_rank() over(partition by category order by total_quantity desc,revenue desc)as rn  from most_selling_pizza
)
select 
	category,
	name, 
	total_quantity,
	concat(round(revenue/1000000 ,2)," M") as revenue 
from ranking
where rn<=3

;
-- Q20. TOP SELLING PIZZAS BY SIZE

with most_selling_pizza as (
	SELECT 
    size,
    name,
     sum(quantity) as total_quantity,
    ROUND(SUM(price * Quantity), 2) AS revenue
FROM
    pizzas P
        JOIN
    order_details od ON od.pizza_id = p.pizza_id
        JOIN
    pizza_types pt ON pt.pizza_type_id = p.pizza_type_id
GROUP BY size,name
),
ranking as (select *,
dense_rank() over(partition by size order by total_quantity desc,revenue desc)as rn  from most_selling_pizza
)
select 
	size,
	name, 
	total_quantity,
   --  sum(total_quantity) over(partition by size) as total,
	concat(round(revenue/1000000 ,2)," M") as revenue 
from ranking
where rn=1



