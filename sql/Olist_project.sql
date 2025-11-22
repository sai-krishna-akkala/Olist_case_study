create database Olist;
use Olist;
-- as we use order_id frequently lets index that column
create index idx_orders_order_id on orders(order_id(32));
create index idx_payments_order_id on payments(order_id(32));
-- weekday Vs weekend sales
create or replace view v_weekday_weekend_sales as
with weekday_weekend as(
  select 
      case 
          when dayofweek(o.order_purchase_timestamp) in (1,7) 
                then "weekend"
		 else "weekday"
	 end as Day_type,
     p.payment_value as p_value
from  orders o 
left join payments p on o.order_id=p.order_id
)
select day_type,concat(round(sum(p_value)/1000000,2)," M") as sales from weekday_weekend
group by day_type;

-- no.of orders with review score 5 and payment type = credit card
create or replace view v_5star_creditcard_orders as
with five_star as (
 select order_id,review_score from reviews where review_score=5 
 ), 
 pay_type as (
   select order_id, payment_type from payments where payment_type="credit_card"
 )
 select 
  concat(round(count(oi.order_id)/100,2)," K") as  orders_with_5star_credit_card
 from order_items oi 
 left join reviews r on oi.order_id=r.order_id
 left join payments p on oi.order_id=p.order_id
 where r.order_id is not null
   and p.order_id is not null;
   
-- avg delivery days for pet_shop
create or replace view v_pet_shop_delivery as
with english_names as (
   select p.product_id, ct.product_category_name_english as category from  products p 
   left join category_translation ct on p.product_category_name=ct.product_category_name
   where ct.product_category_name_english="pet_shop"
   ),
   delivery_days as (
      select oi.product_id,oi.order_id,datediff(o.order_delivered_customer_date,o.order_purchase_timestamp) as days 
	   from order_items oi 
       join orders o on o.order_id=oi.order_id
	)
select round(avg(dd.days),2) as avg_del_pet_shop from english_names en 
left join delivery_days dd on en.product_id=dd.product_id
where dd.order_id is not null;
    
--  avg price and avg payment of customer for sao paulo city
create or replace view v_sao_paulo_avg as
with avg_pay_price as (
  select o.order_id,o.customer_id , oi.price as price, c.customer_city ,p.payment_value as payment
  from orders o
  left join order_items oi on o.order_id=oi.order_id
  left join payments p on o.order_id=p.order_id
  left join customers c on o.customer_id=c.customer_id
  where c.customer_city="sao paulo"
  )
  select round(avg(price),2) as Avg_price, round(avg(payment),2) as avg_payment from avg_pay_price;
  
-- relationship  b/w review score and delivery_days
create or replace view v_review_vs_delivery as
 select r.review_score as review_score , round(avg(datediff(o.order_delivered_customer_date,o.order_purchase_timestamp)),2) as days  
 from orders o
 left join reviews r on o.order_id=r.order_id
 where r.review_score is not null
 group by r.review_score
 order by review_score;
 
-- other kpi's
create or replace view KPIS as 
  with total_order as (
    select concat(round(count(order_id)/1000,2)," K") as total_orders from order_items
    ),
    total_customers as (
     select concat(round(count(customer_unique_id)/1000,2)," K") as total_cust from customers
     ),
	total_payment as (
       select concat(round(sum(payment_value)/1000000,2)," M") as total_pay from payments
       ),
	avg_deli_days as (
         select round(avg(datediff(order_delivered_customer_date,order_purchase_timestamp)),2) as avg_deli_days from orders
		)
	select 
        t.total_orders,
        c.total_cust,
        p.total_pay,
        d.avg_deli_days
	from total_order t
    cross join total_customers c
    cross join total_payment p
    cross join avg_deli_days d;
		
select * from kpis;

-- top 5 product  by payment value
create or replace view v_top_products as
 with pro_name_en as (
   select ct.product_category_name_english as category , p.product_id
   from products p 
   left join category_translation ct on p.product_category_name=ct.product_category_name
   )
   select en.category, concat(round(sum(pa.payment_value)/1000000,2)," M") as payment_value 
   from order_items oi
   left join pro_name_en en on oi.product_id=en.product_id
   left join payments pa on oi.order_id=pa.order_id
   group by en.category
   order by concat(round(sum(pa.payment_value)/1000000,2)," M") desc limit 5;
   
   -- top 5 cities  by payment value
   create or replace view v_top_cities as
   select 
         c.customer_city , 
         concat(round(sum(p.payment_value)/1000000,2)," M") as payment_value
   from orders o
   left join customers c on o.customer_id=c.customer_id
   left join payments p on o.order_id=p.order_id
   group by c.customer_city 
   order by sum(p.payment_value) desc limit 5;
   
-- mom  analysis
create or replace view v_mom_revenue as
with monthly_revenue as (
    select 
        month(o.order_purchase_timestamp) as month_number,
        monthname(o.order_purchase_timestamp) as month_name,
        sum(pa.payment_value) as revenue
    from orders o
    left join payments pa on o.order_id = pa.order_id
    group by month_number, month_name
)

select 
    month_number,
    month_name,
    concat(round(revenue/1000000, 2), ' M') as curr_revenue,
    concat(
        round(lag(revenue) over (order by month_number) / 1000000, 2),
        ' M'
    ) as prev_revenue,
    round(revenue - lag(revenue) over (order by month_number), 2) as abs_change,
    concat(
        round(
            ((revenue - lag(revenue) over (order by month_number)) * 100) 
            / lag(revenue) over (order by month_number),
        2),
        ' %'
    ) as pct_change
from monthly_revenue
order by month_number;

      
   
   
   
   


       






 
 
 
     
     
          
