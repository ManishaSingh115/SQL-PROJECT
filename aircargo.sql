CREATE database IF NOT exists AIR_CARGO;
USE AIR_CARGO;
CREATE table IF NOT exists CUSTOMERS(
customer_id tinyint primary key,
first_name varchar(25) NOT null,
last_name varchar(25) not null,
date_of_birth date not null,
gender char(1) not null
);
create table if not exists passengers(
customer_id tinyint not null,
aircraft_id varchar(25) not null,
route_id tinyint not null,
depart varchar(5) not null,
arrival varchar(5) not null,
seat_num varchar(15) not null unique,
class_id varchar(25) not null,
travel_date date not null,
flight_num smallint not null
);
create table if not exists tickets(
p_date date not null,
customer_id tinyint not null,
aircraft_id varchar(25) not null,
class_id varchar(25) not null,
no_of_tickets tinyint not null,
a_code varchar(5) not null,
Price_per_ticket smallint not null,
brand varchar(25) not null
);
create table if not exists routes(
route_id tinyint primary key unique,
flight_num smallint not null,
origin_airport varchar(5) not null,
destination_airport	varchar(5) not null,
aircraft_id	varchar(25) not null,
distance_miles smallint not null
);

select * from passengers
where route_id between 1 and 25
order by route_id,customer_id ; 

select count(*) as 'num of passengers',
sum(price_per_ticket)
from tickets
where class_id='bussiness';

select concat(first_name,' ',last_name) as CUSTOMER_NAME 
from customers 
order by customer_id;

select * from customers as c
where exists(select 1 from tickets as t
where t.customer_id=c.customer_id)
order by customer_id;

with brands as(
select brand,customer_id from tickets
where brand='emirates')
select c.customer_id,first_name,last_name,brand from customers as c
inner join brands as b on
c.customer_id=b.customer_id
order by c.customer_id;

select customer_id,count(customer_id) as 'num of travels'
from passengers
where class_id='economy plus'
group by customer_id
having count(customer_id)>=1;

select if(sum(no_of_tickets*Price_per_ticket)>10000,
         'YES,Revenue crossed 10000','No,Revenue did not cross 10000') as result
from tickets;

 select class_id,Price_per_ticket,
 max(Price_per_ticket) OVER (partition by class_id) AS MAX_FOR_CLASS
 from tickets
 order by class_id;

create index route_idx on passengers(route_id);
select * from passengers where route_id=4;

explain analyze select * from passengers where route_id=4;

select customer_id,aircraft_id,sum(no_of_tickets*Price_per_ticket) as 'total price'
from tickets
group by
customer_id,aircraft_id with rollup;

create or replace view business as 
with bus as(
select customer_id,class_id,brand from tickets
where class_id='bussiness')
select c.customer_id,concat(first_name,' ',last_name) as 'Customer name',class_id,brand from customers as c
inner join bus as b on
c.customer_id=b.customer_id  
order by c.customer_id;
select * from business;

delimiter %%
create procedure by_route(
in p_from_route int,
in p_to_route int,
out o_message varchar(100)
)
begin
select c.customer_id,c.first_name,c.last_name,p.route_id
from passengers as p
inner join customers as c on
c.customer_id=p.customer_id
where p.route_id between p_from_route and p_to_route
order by route_id;
end%%
call by_route (1,25);
delimiter %%

create procedure by_dist()
begin
select * from routes where distance_miles>=2000
order by route_id;
end%%
call by_dist();
delimiter%%

create procedure miles_classifier()
begin
select flight_num,
case 
when sum(distance_miles)<=2000 then 'LDT'
when sum(distance_miles)<=6500 then 'MDT'
else 'LDT'
end as classification
from routes
group by flight_num;
end%%
call miles_classifier();
delimiter%%

create function getcompservice(
class_id varchar(25)
)
returns varchar (25)
deterministic
begin
declare compservice varchar(20);
if class_id in ('Bussiness','Economy Plus') then
set compservice='Yes';
else 
set compservice='No';
end if;
return(compservice);
end%%
select *,getcompservice(class_id) as 'Complimentory Service' from passengers;
delimiter%%

create procedure getCustName()
begin
declare finished INTEGER DEFAULT 0;
declare full_name varchar(100) default "";
declare dob date;
declare gender char(1);
--
declare getCustomer
 cursor for
  select customer_id,concat(first_name,' ',last_name) as full_name,date_of_birth,gender 
  from customers
  where last_name='scott';
  --
declare continue handler
 for not found set finished=1;
open getCustomer;
cust:loop
 fetch getCustomer into full_name,dob,gender;
 if finished=1 then
 leave cust;
 end if;
 select full_name,dob,gender;
 end loop cust;
 close getCustomer;
 end%%
 
call getCustName();