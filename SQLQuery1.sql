select * from swiggy_data

---data validation & cleaning
--null check
select
      SUM(case when state is null then 1 else 0 end) as null_state,
      SUM(case when city is null then 1 else 0 end ) as null_city,
      SUM(case when order_date is null then 1 else 0 end) as null_order_date,
      SUM(case when restaurant_name is null then 1 else 0 end) as null_restaurant_name,
      SUM(case when location is null then 1 else 0 end) as location,
      SUM(case when category is null then 1 else 0 end) as null_category,
      SUM(case when dish_name is null then 1 else 0 end) as null_dish_name,
      SUM(case when price_inr is null then 1 else 0 end) as null_price_inr,
      SUM(case when rating is null then 1 else 0 end) as null_rating,
      SUM(case when rating_count is null then 1 else 0 end) as null_rating_count
      from swiggy_data;



---Blank And Empty String
select *
from swiggy_data
where
State ='' or City = '' or Order_Date = '' or Restaurant_Name = '' or Location = '' or Category = '' or Dish_Name = '';


---duplication detection
select
state, city, order_date, restaurant_name, location, category,
dish_name, Price_inr, rating, rating_count, COUNT(*) as cnt
from swiggy_data
group by
state, city, order_date, restaurant_name, location, category,
dish_name, Price_inr, rating, rating_count
having COUNT(*)>1;

---delete duplication
with cte as (
select *, row_number () over(
  partition by state, city, order_date, restaurant_name, location, category,
dish_name, Price_inr, rating, rating_count
order by (select null)
) as rn
from swiggy_data
)
delete from cte where rn>1

---creating schema
---demension table
---data table
Create Table dim_date(
  date_id int identity(1,1) primary key,
  Full_date date,
  Year int,
  Month int,
  Month_Name varchar(20),
  Quarter int,
  Day int,
  Week int
  )

 ---dim_location
 create table dim_location(
 Location_id int identity(1,1) primary key,
 State varchar(100),
 City varchar(100),
 Location varchar(200)
 );

 ---dim_restaurant
 create table dim_restaurant(
 Restaurant_id int identity(1,1) primary key,
 Restaurant_Name varchar(200)
 );


 ---dim_category
 create table dim_category(
 Category_id int identity(1,1) primary key,
 Category varchar(200)
 );

 ---dim_dish
 create table dim_dish(
 Dish_id int identity(1,1) primary key,
 Dish_Name varchar(200)
 );


 ---fact table
 create table fact_swiggy_orders(
 order_id int identity(1,1) primary key,
 Date_id int,
 Price_INR Decimal(10,2),
 Rating decimal(4,2),
 Rating_count int,
 Location_id int,
 Restaurant_id int,
 Category_id int,
 Dish_id int,

 foreign key (date_id) references dim_date(date_id),
 foreign key (location_id) references dim_location(location_id),
 foreign key (restaurant_id ) references dim_restaurant(restaurant_id),
 foreign key (category_id) references dim_category(category_id),
 foreign key (dish_id) references dim_dish(dish_id)
 );

 select * from fact_swiggy_orders
 
 ---insert data in tables

insert into dim_date(Full_date, Year, Month, Month_Name, Quarter, Day, Week)
select distinct
order_date,
YEAR(order_date),
MONTH(order_date),
datename(month,order_date),
DATEPART(quarter,order_date),
DAY(order_date),
DATEPART(week, order_date)
from swiggy_data
where Order_Date is not null;

select * from dim_location


---dim_location
insert into dim_location(State, City, Location)
select distinct
STATE,
City,
Location
from swiggy_data;

---dim_restraurant
insert into dim_restaurant(Restaurant_Name)
select distinct
    Restaurant_Name
from swiggy_data;

---dim_category
insert into dim_category(category)
select distinct
   Category
from swiggy_data;

---dim_dish
insert into dim_dish(Dish_Name)
select distinct
   Dish_Name
from swiggy_data;

----insert fact tables data

insert into fact_swiggy_orders(
Date_id,
Price_INR,
Rating,
Rating_count,
Location_id,
Restaurant_id,
Category_id,
Dish_id
)
select
dd.date_id,
s.price_inr,
s.rating,
s.rating_count,
dl.location_id,
dr.Restaurant_id,
dc.category_id,
dsh.dish_id
from swiggy_data s

join dim_date dd
    on dd.Full_date = s.Order_Date

join dim_location dl
    on dl .State = s.State
    and dl .City = s.City
    and dl.Location = s.Location

join dim_Restaurant dr
    on dr.Restaurant_Name = s.Restaurant_Name

join dim_category dc
   on dc.Category = s.Category

join dim_dish dsh
   on dsh.Dish_Name = s.Dish_Name;

select * from fact_swiggy_orders

select * from fact_swiggy_orders f
join dim_date d on f.Date_id = d.date_id
join dim_location l on f.Location_id = l.Location_id
join dim_restaurant r on f.Restaurant_id = r.Restaurant_id
join dim_category c on f.Category_id = c.Category_id
join dim_dish di on f.Dish_id = di.Dish_id;

---KPIs
---Total Ordres
select COUNT(*) as Total_order
from fact_swiggy_orders;

--Total Revenue
select 
format(sum(convert(float,price_inr))/1000000, 'N2')+ 'inr million' 
as Total_Revenue 
from fact_swiggy_orders;

--AverageDish Price
select 
format(AVG(convert(float,price_inr)), 'N2')+ 'inr' 
as Average_Dish_Price 
from fact_swiggy_orders;

--Average Rating
Select
AVG(Rating) as Average_Rating
from fact_swiggy_orders;

--Deep Dive Bussion Analysis

--Monthly Order Trends
select
d.year,
d.month,
d.month_name,
sum(price_inr) as Total_Revenue
from fact_swiggy_orders f
join dim_date d on f.date_id = d.date_id
group by d.year,
d.month,
d.month_name
order by sum(price_inr) desc;

--Quarterly Order Trends
select
d.year,
d.Quarter,
COUNT(*) as Total_Orders
from fact_swiggy_orders f
join dim_date d on f.date_id = d.date_id
group by d.year,
d.Quarter
order by count(*) desc;

--Yearly Order Trends
select
d.year,
COUNT(*) as Total_Orders
from fact_swiggy_orders f
join dim_date d on f.date_id = d.date_id
group by d.year
order by count(*) desc;

--Order By Day Of Week(Mon-Sun)
select
    DATENAME(WEEKDAY, d.full_date) as day_name,
    COUNT(*) as Total_Orders
from fact_swiggy_orders f
join dim_date d on f.Date_id = d.date_id
group by DATENAME(weekday, d.Full_date), DATEPART(weekday, d.Full_date)
order by DATEPART(WEEKDAY, d.Full_date);

--Top 10 Cities By Order Volumes
select top 10
l.city,
sum(f.price_inr) as Total_Revenue from fact_swiggy_orders f
join dim_location l
on l.location_id = f.location_id
group by l.city
order by sum(f.price_inr) desc;

--Revenue Contribution by state
select
l.State,
sum(f.price_inr) as Total_Revenue from fact_swiggy_orders f
join dim_location l
on l.location_id = f.location_id
group by l.State
order by sum(f.price_inr) desc;

--Top 10 Restaurant BY Orders
select top 10
r.restaurant_name,
sum(f.price_inr) as Total_Revenue from fact_swiggy_orders f
join dim_restaurant r
on r.Restaurant_id = f.Restaurant_id
group by r.Restaurant_Name
order by sum(f.price_inr) desc;

--Top categories By Order Volume
select
    c.category,
    count(*) as total_orders
from fact_swiggy_orders f
join dim_category c on f.category_id = c.category_id
group by c.category
order by total_orders desc;

--Most Orders Dishes
select
   d.dish_name,
   count(*) as order_count
from fact_swiggy_orders f
join dim_dish d on f.Dish_id = d.Dish_id
group by d.Dish_Name
ORDER BY order_count desc;

--cuision Performance (order + avg_rating)
select 
    c.category,
    count(*) as total_orders,
    AVG(f.rating) as avg_rating
from fact_swiggy_orders f
join dim_category c on f.category_id = c.category_id
group by c.category
order by total_orders desc;

--Top Orders by price range
select
   case
       when convert (float, price_inr)< 100 then'under 100'
       when convert (float, price_inr) between 100 and 199 then '100 - 199'
       when convert (float,price_inr) between 100 and 299 then '200 - 299'
       when convert (float,price_inr) between 300 and 499 then '300 - 499'
       else '500+'
    end as price_range,
    count(*) as  total_orders
from fact_swiggy_orders
group by 
   case
    when convert (float,price_inr) < 100 then 'under 100'
    when convert (float, price_inr) between 100 and 199 then '100 - 199'
       when convert (float,price_inr) between 100 and 299 then '200 - 299'
       when convert (float,price_inr) between 300 and 499 then '300 - 499'
       else '500+'
    end
order by total_orders desc; 

--Rating Count Distrubution(1-5)
select
    rating,
    count(*) as rating_count
from fact_swiggy_orders
group by Rating
order by Rating desc;