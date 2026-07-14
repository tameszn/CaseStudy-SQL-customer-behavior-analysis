create database projects;
use projects;


--creating the first table SALES
--The sales table captures all customer_id level purchases with an corresponding order_date and product_id information for when and what menu items were ordered.
CREATE TABLE sales(
	customer_id VARCHAR(1),
	order_date DATE,
	product_id INTEGER
);



--Inserting rows to table SALES 
INSERT INTO sales
	(customer_id, order_date, product_id)
VALUES
   ('A', '2021-01-01', 1),
	('A', '2021-01-01', 2),
	('A', '2021-01-07', 2),
	('A', '2021-01-10', 3),
	('A', '2021-01-11', 3),
	('A', '2021-01-11', 3),
	('B', '2021-01-01', 2),
	('B', '2021-01-02', 2),
	('B', '2021-01-04', 1),
	('B', '2021-01-11', 1),
	('B', '2021-01-16', 3),
	('B', '2021-02-01', 3),
	('C', '2021-01-01', 3),
	('C', '2021-01-01', 3),
	('C', '2021-01-07', 3);


 --creating the second table MENU 
 --The menu table maps the product_id to the actual product_name and price of each menu item.
CREATE TABLE menu(
	product_id INTEGER,
	product_name VARCHAR(5),
	price INTEGER
);

--Inserting rows to table MENU
INSERT INTO menu
	(product_id, product_name, price)
VALUES
	(1, 'sushi', 10),
    (2, 'curry', 15),
    (3, 'ramen', 12);



 --creating the third table members
 --The final members table captures the join_date for each customer_id

CREATE TABLE members(
	customer_id VARCHAR(1),
	join_date DATE
);


INSERT INTO members
	(customer_id, join_date)
VALUES
	('A', '2021-01-07'),
    ('B', '2021-01-09');




--FOLLOWING QUERIES CAN BE USED TO ANSWER THE CASE STUDY QUESTIONS IN ORDER 





--QUERY1 
SELECT sales.customer_id, SUM(menu.price) AS total_amount_spent
FROM sales
INNER JOIN menu
ON sales.product_id = menu.product_id
GROUP BY sales.customer_id;



--QUERY2
SELECT sales.customer_id, COUNT(DISTINCT sales.order_date) AS total_days_visited
FROM sales
GROUP BY sales.customer_id;





--QUERY 3 
WITH customer_first_purchase AS(
	SELECT s.customer_id, MIN(s.order_date) AS first_purchase_date
	FROM dbo.sales s
	GROUP BY s.customer_id
)
SELECT cfp.customer_id, cfp.first_purchase_date, m.product_name
FROM customer_first_purchase cfp
INNER JOIN dbo.sales s ON s.customer_id = cfp.customer_id
AND cfp.first_purchase_date = s.order_date
INNER JOIN dbo.menu m on m.product_id = s.product_id;



--query 4 

SELECT TOP 1 menu.product_name, COUNT(sales.product_id) AS total_purchased
FROM sales 
INNER JOIN menu on sales.product_id = menu.product_id
GROUP BY menu.product_name
ORDER BY total_purchased DESC;






-- 5

WITH customer_popularity AS (
    SELECT s.customer_id, m.product_name, COUNT(*) AS purchase_count,
        DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY COUNT(*) DESC) AS rank
    FROM sales s
    INNER JOIN menu m ON s.product_id = m.product_id
    GROUP BY s.customer_id, m.product_name
)
SELECT customer_id, product_name, purchase_count
FROM customer_popularity
WHERE rank = 1;




-- QUERY 6
WITH cte AS
(
SELECT
s.customer_id,
m.product_name,
s.order_date,
ROW_NUMBER() OVER    --row number() used to rank the purchases made by each customer based on the order_date in ascending order
(
PARTITION BY s.customer_id
ORDER BY s.order_date
) AS rn
FROM sales s
JOIN members mem
ON s.customer_id=mem.customer_id
JOIN menu m
ON s.product_id=m.product_id
WHERE s.order_date>mem.join_date  --filter to return only the purchases made after the customer joined the membership
)

SELECT customer_id,
product_name,
order_date
FROM cte
WHERE rn=1;  



-- QUERY7

WITH cte AS
(
SELECT
s.customer_id,
m.product_name,
s.order_date,
ROW_NUMBER() OVER    --row number() used to rank the purchases made by each customer based on the order_date in ascending order
(
PARTITION BY s.customer_id
ORDER BY s.order_date DESC
) AS rn
FROM sales s
JOIN members mem
ON s.customer_id=mem.customer_id
JOIN menu m
ON s.product_id=m.product_id
WHERE s.order_date<mem.join_date  --filter to return only the purchases made after the customer joined the membership
)

SELECT customer_id,
product_name,
order_date
FROM cte
WHERE rn=1;  


-- QUERY8
select sales.customer_id,count(*) as total_items_purchased, sum(menu.price) as total_amount_spent
from sales join menu on sales.product_id=menu.product_id
join members on sales.customer_id=members.customer_id
where sales.order_date<members.join_date
group by sales.customer_id



-- QUERY 9
--CASE is used to assign different point values based on the product_name. If the product_name is 'sushi', then the points are calculated as price*20, otherwise price*10. The total points for each customer_id are then summed up and grouped by customer_id.
--If all items were equally weighted then the query would be simplified to just summing up the price of all items purchased by each customer_id without any conditional logic.
SELECT
s.customer_id,
SUM(
CASE
WHEN m.product_name='sushi'
THEN m.price*20
ELSE m.price*10
END
) AS total_points
FROM sales s
JOIN menu m
ON s.product_id=m.product_id
GROUP BY s.customer_id;





--QUERY10

--cases used to assign different point values based on the product_name and the order_date. If the order_date is within 7 days of the join_date, then the points are calculated as price*20. If the product_name is 'sushi', then the points are also calculated as price*20. Otherwise, the points are calculated as price*10. The total points for each customer_id are then summed up and grouped by customer_id.
--case 1 for customers who joined the membership and made purchases within 7 days of joining, 
--case 2 for customers who purchased sushi 
--case 3 for all other purchases. 
--The query also filters the results to only include customers who are members and have made purchases before or on '2021-01-31'.
SELECT s.customer_id, SUM(
    CASE 
        WHEN s.order_date BETWEEN mb.join_date AND DATEADD(day, 7, mb.join_date)
        THEN m.price*20
        WHEN m.product_name = 'sushi' THEN m.price*20 
        ELSE m.price*10 
    END) AS total_points
FROM dbo.sales s
JOIN dbo.menu m ON s.product_id = m.product_id
LEFT JOIN dbo.members mb ON s.customer_id = mb.customer_id
--WHERE s.customer_id IN ('A', 'B') AND s.order_date <= '2021-01-31'
WHERE s.customer_id = mb.customer_id AND s.order_date <= '2021-01-31'
GROUP BY s.customer_id;









--11. Recreate the table output using the available data

SELECT s.customer_id, s.order_date, m.product_name, m.price,
CASE WHEN s.order_date >= mb.join_date THEN 'Y'
ELSE 'N' END AS member
FROM sales s
JOIN menu m ON s.product_id = m.product_id
LEFT JOIN members mb ON s.customer_id = mb.customer_id
ORDER BY s.customer_id, s.order_date;

--12. Rank all the things:

WITH customers_data AS (
	SELECT s.customer_id, s.order_date, m.product_name, m.price,
	CASE
		WHEN s.order_date < mb.join_date THEN 'N'
		WHEN s.order_date >= mb.join_date THEN 'Y'
		ELSE 'N' END AS member
	FROM sales s
	LEFT JOIN members mb ON s.customer_id = mb.customer_id
	JOIN menu m ON s.product_id = m.product_id
)
SELECT *,
CASE WHEN member = 'N' THEN NULL
ELSE RANK() OVER(PARTITION BY customer_id, member ORDER BY order_date)
END AS ranking
FROM customers_data
ORDER BY customer_id, order_date;