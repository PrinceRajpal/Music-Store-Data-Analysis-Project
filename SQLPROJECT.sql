/* THIS SQL PROOJECT INVOLVES QUESTIONS BASED ON A MUSIC STORE DATABASE AND ITS MANAGMENT*/

/*	Question Set 1 - Easy */
 
/* Q1. Who is the senior most employee based on job title?*/ 

SELECT * FROM employee
ORDER BY levels DESC
LIMIT 1;


/* Q2. Which countries have the most Invoices?*/

SELECT billing_country , COUNT(*) AS "Total Invoice"
FROM invoice
GROUP BY billing_country
ORDER BY "Total Invoice" DESC;


/* Q3. What are top 3 values of total invoice? */

SELECT total AS "Total Invoice Amount"
FROM invoice
ORDER BY total DESC
LIMIT 3;


/* Q4. Which city has the best customers? We would like to throw a promotional Music
Festival in the city we made the most money. Write a query that returns one city that
has the highest sum of invoice totals. Return both the city name & sum of all invoice
totals */

SELECT DISTINCT SUM(total) OVER(PARTITION BY billing_city) AS "Sum of invoice" , billing_city AS "City"
FROM invoice 
ORDER BY "Sum of invoice" DESC
LIMIT 1;


/* Q5. Who is the best customer? The customer who has spent the most money will be
declared the best customer. Write a query that returns the person who has spent the
most money */

SELECT DISTINCT c.customer_id , first_name , last_name , SUM(total) OVER(PARTITION BY first_name , last_name) AS "Sum of invoice" 
FROM invoice AS i
JOIN customer AS c
ON i.customer_id = c.customer_id
ORDER BY "Sum of invoice" DESC
LIMIT 1;


/* Question Set 2 - Moderate */

/* Q1: Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
Return your list ordered alphabetically by email starting with A. */


SELECT DISTINCT email , first_name , last_name , g.name 
FROM customer AS c
JOIN invoice AS i
ON c.customer_id = i.customer_id
JOIN invoice_line AS il
ON i.invoice_id = il.invoice_id
JOIN track AS t
ON il.track_id = t.track_id
JOIN genre AS g
ON t.genre_id = g.genre_id
WHERE g.name LIKE 'Rock'
ORDER  BY email ASC;


/* Q2: Let's invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands. */

SELECT a.name , COUNT(*) AS "Track Count"
FROM artist AS a
JOIN album AS al
ON a.artist_id = al.artist_id
JOIN track AS t 
ON al.album_id = t.album_id
JOIN genre AS g
ON t.genre_id = g.genre_id
WHERE g.name LIKE 'Rock'
GROUP BY a.name
ORDER BY "Track Count" DESC
LIMIT 10;


/* Q3: Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track.
Order by the song length with the longest songs listed first. */

SELECT name,milliseconds
FROM track
WHERE milliseconds > (
	SELECT AVG(milliseconds) AS avg_track_length
	FROM track )
ORDER BY milliseconds DESC;


/* Question Set 3 - Advance */

/* Q1: Find how much amount spent by each customer on the top artist?
Write a query to return customer name, artist name and total spent */

/* How I solved it? First I found the top artist by finding the artist who earned the most,
and stored it on a cte. Then I found each customer who spent the amount on that particular
artist using the cte's result.(It's the simple definition of the query)*/

WITH best_artist AS (
SELECT  a.artist_id AS artist_id , a.name AS artist_name , SUM(il.unit_price * il.quantity) OVER (PARTITION BY a.artist_id) AS total_earned
FROM artist AS a
JOIN album AS al ON a.artist_id = al.artist_id
JOIN track AS t ON al.album_id = t.album_id
JOIN invoice_line AS il ON t.track_id = il.track_id
ORDER BY total_earned DESC
LIMIT 1
)
SELECT first_name , last_name , bsa.artist_name , SUM(il.unit_price * il.quantity ) AS "Total Spent"
FROM invoice i
JOIN customer c ON c.customer_id = i.customer_id
JOIN invoice_line il ON il.invoice_id = i.invoice_id
JOIN track t ON t.track_id = il.track_id
JOIN album alb ON alb.album_id = t.album_id
JOIN best_artist bsa ON bsa.artist_id = alb.artist_id
GROUP BY 1,2,3
ORDER BY "Total Spent" DESC;


/* Q2: We want to find out the most popular music Genre for each country.
We determine the most popular genre as the genre with the highest amount of purchases.
Write a query that returns each country along with the top Genre. For countries where 
the maximum number of purchases is shared return all Genres. */

/* How I solved it? First I made a cte to find the most popular music genre per country and
assigned it a row number by total quantity sold descending and then called the ones with row
number 1, the top genre per country and amount sold.*/

WITH mpmgpc AS (
SELECT g.name AS "Genre Name" ,i.billing_country AS country , SUM(il.quantity) AS "Total quantity sold" , ROW_NUMBER() OVER(PARTITION BY i.billing_country ORDER BY SUM(il.quantity) DESC) AS rowno
FROM genre g
JOIN track t ON g.genre_id = t.genre_id
JOIN album al ON t.album_id = al.album_id
JOIN artist a ON al.artist_id = a.artist_id
JOIN invoice_line il ON t.track_id = il.track_id
JOIN invoice i ON il.invoice_id = i.invoice_id
GROUP BY 1 , 2 
ORDER BY "Total quantity sold" DESC , i.billing_country ASC
)
SELECT * FROM mpmgpc WHERE rowno <= 1;


/* Q3: Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */

/* How I solved it? I made a cte to find the most valueable customer per country and gave each 
customer from respective country a row number and then called the cte outside with all the 
person with row number 1 , the top customersfrom each country*/

WITH mvcpc AS (
SELECT c.first_name , c.last_name , i.billing_country , SUM(total) AS "Total Spent" , ROW_NUMBER() OVER(PARTITION BY i.billing_country  ORDER BY SUM(total) DESC) AS rowno
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY 1,2,3
ORDER BY 3 ASC , 4 DESC
)
SELECT * FROM mvcpc WHERE rowno <= 1
