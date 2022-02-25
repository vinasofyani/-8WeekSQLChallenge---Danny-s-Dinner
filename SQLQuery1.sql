--1. what is the total amount of each customer spent at the restaurant

SELECT s.customer_id, SUM (m.price) as amount
FROM sales s
LEFT JOIN menu m ON s.product_id=m.product_id
GROUP BY s.customer_id

-- 2. How many days has each customer visited the restaurant
SELECT s.customer_id,COUNT(DISTINCT(order_date)) as times
FROM sales s
LEFT JOIN menu m ON s.product_id=m.product_id
GROUP BY s.customer_id

-- 3. What was the first item from the menu purchased by each customer ?
SELECT s.customer_id, m.product_name, s.order_date, DENSE_RANK () OVER (PARTITION BY s.customer_id ORDER BY s.order_date)AS rank
FROM sales s
LEFT JOIN menu m ON s.product_id=m.product_id

SELECT customer_id, product_name
FROM 
	(SELECT s.customer_id, m.product_name, s.order_date, DENSE_RANK () OVER (PARTITION BY s.customer_id ORDER BY s.order_date)AS rank
	FROM sales s
	LEFT JOIN menu m ON s.product_id=m.product_id
	) a
WHERE rank =1

--4. What is the most purchased item on the menu and how many times was it purchased by all customers
SELECT TOP 1 m.product_name, COUNT(s.product_id) as times
FROM sales AS s
LEFT JOIN menu m ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY times DESC

--5.Which item was the most popular for each customer ?
SELECT s.customer_id, m.product_name, COUNT (s.product_id) as jumlah_produk
FROM sales s
LEFT JOIN menu m ON s.product_id=m.product_id
GROUP BY s.customer_id, m.product_name

--6. Which item was purchased first item after they became a member ?
SELECT TOP 2 s.customer_id, m.product_name, s.order_date, ms.join_date
FROM sales s 
LEFT JOIN menu m ON s.product_id=m.product_id
LEFT JOIN members ms ON s.product_id=m.product_id
WHERE ms.join_date <= s.order_date
ORDER BY DENSE_RANK () OVER (PARTITION BY s.customer_id ORDER BY s.order_date)

-- CARA LAIN

SELECT TOP 2 r.customer_id, m.product_name, r.order_date, r.join_date, DENSE_RANK () OVER (PARTITION BY r.customer_id ORDER BY r.order_date) as rangking
FROM (SELECT s.customer_id, m.product_name, s.order_date, ms.join_date
		FROM sales s 
		LEFT JOIN menu m ON s.product_id=m.product_id
		LEFT JOIN members ms ON s.product_id=m.product_id
		WHERE s.order_date >= ms.join_date
	) as r
LEFT JOIN menu m ON r.product_name = m.product_name
ORDER BY rangking

-- NGIDE NYOBAK NYOBAK

SELECT r.customer_id, m.product_name, r.order_date, r.join_date, DENSE_RANK () OVER (PARTITION BY r.customer_id ORDER BY r.order_date) as rangking
FROM (SELECT s.customer_id, m.product_name, s.order_date, ms.join_date
		FROM sales s 
		LEFT JOIN menu m ON s.product_id=m.product_id
		LEFT JOIN members ms ON s.product_id=m.product_id
		WHERE s.order_date >= ms.join_date
	) as r
LEFT JOIN menu m ON r.product_name = m.product_name
ORDER BY rangking

-- 7. Which item was purchased just before the customer became a member ?
SELECT s.customer_id, m.product_name, s.order_date, ms.join_date   
FROM sales s
LEFT JOIN menu m ON s.product_id=m.product_id
LEFT JOIN members ms ON s.customer_id = ms.customer_id
WHERE s.order_date < ms.join_date

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT s.customer_id, m.product_name, s.order_date, ms.join_date, COUNT (DISTINCT s.product_id) AS unique_order, SUM (m.price) AS jumlah_harga 
FROM sales s
LEFT JOIN menu m ON s.product_id=m.product_id
LEFT JOIN members ms ON s.customer_id = ms.customer_id
WHERE s.order_date < ms.join_date
GROUP BY s.customer_id,m.product_name,s.order_date,ms.join_date

-- TOTAL KESELURUHAN SETIAP CUSTOMER
SELECT s.customer_id, COUNT (DISTINCT s.product_id) AS unique_order, SUM (m.price) AS jumlah_harga 
FROM sales s
LEFT JOIN menu m ON s.product_id=m.product_id
LEFT JOIN members ms ON s.customer_id = ms.customer_id
WHERE s.order_date < ms.join_date
GROUP BY s.customer_id

-- 9. If each $1 spent equates to 10 points and sushi has 2x points multiplier - how many points would each cutomer have ?
-- Menggunakan CASE WHEN karena ada 2 kondisi dimana
-- *Setiap 1$ untuk semua produk mendapat 10 points kecuali shusi
-- *Setiap 1$ untuk semua produk mendapat 20 points
SELECT *,
CASE 
	WHEN m.product_name = 'sushi' THEN m.price*20
	ELSE m.price*10
	END  AS points
FROM menu m
	
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items,
	-- not just sushi - how many point do customer A and B have at the end of January ?
-- Ind : Pada 1 minggu pertama setelah pelanggan mengikuti program (termasuk tanggal bergabungnya), mereka mendapatkan
-- 2x poin untuk semua item, bukan hanya sushi - berapa poin yang dimiliki pelanggan A dan B pada akhir januari ?
SELECT *,
DATEADD (DAY, 6, ms.join_date) AS aweek_from_joindate
FROM members ms

SELECT s.customer_id, m.product_name, s.order_date, ms.join_date, COUNT (s.product_id) AS jumlah_produk, DATEADD (DAY, 6, ms.join_date) AS aweek_from_joindate,
SUM (CASE 
WHEN m.product_name = 'sushi' THEN 2*10*m.price
WHEN  s.order_date BETWEEN ms.join_date AND DATEADD (DAY, 6, ms.join_date) THEN 2*10*m.price
ELSE m.price*10
END) AS points
FROM sales s
LEFT JOIN menu m ON s.product_id = m.product_id
LEFT JOIN members ms ON s.customer_id = ms.customer_id
WHERE s.order_date <= '2021-01-31'
GROUP BY s.customer_id, m.product_name, s.order_date, ms.join_date, m.price

-- Jumlah poin setiap customer 
SELECT ts.customer_id, SUM (ts.points) as poin
FROM (SELECT s.customer_id, m.product_name, s.order_date, ms.join_date, 
DATEADD (DAY, 6, ms.join_date) AS aweek_from_joindate,
CASE
WHEN m.product_name = 'sushi' THEN 2*10*m.price
WHEN s.order_date BETWEEN ms.join_date AND DATEADD (DAY, 6, ms.join_date) THEN 2*10*m.price
ELSE m.price*10
END AS points
FROM sales s
LEFT JOIN menu m ON s.product_id=m.product_id
LEFT JOIN members ms ON s.customer_id=ms.customer_id 
WHERE s.order_date <= '2021-01-31'
GROUP BY s.customer_id, m.product_name, s.order_date, ms.join_date,m.price) AS ts
GROUP BY ts.customer_id

--PERTANYAAN BONUS
SELECT s.customer_id, s.order_date, m.product_name, m.price,
CASE 
WHEN s.order_date < ms.join_date THEN 'N'
WHEN s.order_date >= ms.join_date THEN 'Y'
ELSE 'N'
END AS member
FROM sales as s
LEFT JOIN menu m ON s.product_id=m.product_id
LEFT JOIN members ms ON s.customer_id=ms.customer_id

-- RANK ALL THE THINGS
-- KETIKA MEMBER = N MAKA DIRANK NULL, GUNAKAN RANK NULL
SELECT *,
CASE WHEN tb.member ='N' THEN NULL
ELSE RANK () OVER (PARTITION BY tb.customer_id, tb.member ORDER BY tb.order_date)
END as rank
FROM (SELECT s.customer_id, s.order_date, m.product_name, m.price,
CASE 
WHEN s.order_date < ms.join_date THEN 'N'
WHEN s.order_date >= ms.join_date THEN 'Y'
ELSE 'N'
END AS member
FROM sales as s
LEFT JOIN menu m ON s.product_id=m.product_id
LEFT JOIN members ms ON s.customer_id=ms.customer_id) AS tb


SELECT s.customer_id, SUM (m.price) as amount
FROM sales s
LEFT JOIN menu m ON s.product_id=m.product_id
GROUP BY s.customer_id
