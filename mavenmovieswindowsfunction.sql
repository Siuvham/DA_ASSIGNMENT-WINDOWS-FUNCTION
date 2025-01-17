
use mavenmovies;

-- Q. 01 Rank the customers based on the total amount they've spent on rentals.
WITH CustomerRanking AS (
    SELECT customer_id, SUM(amount) AS total_amount_spent,
        RANK() OVER (ORDER BY SUM(amount) DESC) AS customer_rank
    FROM payment
    GROUP BY customer_id
)
SELECT customer_id, total_amount_spent, customer_rank
FROM CustomerRanking;


-- Q. 02 Calculate the cumulative revenue generated by each film over time.
SELECT f.film_id, f.title, p.payment_date, SUM(p.amount) 
OVER (PARTITION BY f.film_id ORDER BY p.payment_date) AS cumulative_revenue
FROM payment p JOIN rental r ON p.rental_id = r.rental_id
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
ORDER BY f.film_id, p.payment_date;


-- Q. 03 Determine the average rental duration for each film, considering films with similar lengths.*

SELECT film_id, title, rental_duration, AVG(rental_duration) OVER (PARTITION BY length) 
AS avg_rental_duration
FROM film
WHERE length IS NOT NULL;


-- Q. 04 Identify the top 3 films in each category based on their rental counts

WITH RankedFilms AS (
    SELECT fc.category_id, fc.film_id, f.title,
        ROW_NUMBER() OVER (PARTITION BY fc.category_id ORDER BY COUNT(r.rental_id) DESC) AS ranking
    FROM film_category fc
    JOIN rental r ON fc.film_id = r.inventory_id
    JOIN film f ON fc.film_id = f.film_id
    GROUP BY fc.category_id, fc.film_id, f.title
)
SELECT category_id, film_id, title, ranking
FROM RankedFilms
WHERE ranking <= 3;


-- Q. 05 Calculate the difference in rental counts between each customer's total rentals and the average rentals
-- across all customers.

WITH CustomerRentalDifference AS (
    SELECT
        customer_id,
        COUNT(rental_id) AS total_rentals,
        AVG(COUNT(rental_id)) OVER () AS avg_rentals_across_customers,
        COUNT(rental_id) - AVG(COUNT(rental_id)) OVER () AS rental_difference
    FROM
        rental
    GROUP BY
        customer_id
)
SELECT
    customer_id,
    total_rentals,
    avg_rentals_across_customers,
    rental_difference
FROM
    CustomerRentalDifference;


-- Q. 06 Find the monthly revenue trend for the entire rental store over time.

WITH MonthlyRevenue AS (
    SELECT
        DATE_FORMAT(payment_date, '%Y-%m') AS month,
        SUM(amount) AS total_revenue
    FROM
        payment
    GROUP BY
        DATE_FORMAT(payment_date, '%Y-%m')
)
SELECT
    month,
    total_revenue,
    SUM(total_revenue) OVER (ORDER BY month) AS cumulative_revenue
FROM
    MonthlyRevenue
ORDER BY
    month;


-- Q. 07 Identify the customers whose total spending on rentals falls within the top 20% of all customers

WITH CustomerSpending AS (
    SELECT
        customer_id,
        SUM(amount) AS total_spending,
        RANK() OVER (ORDER BY SUM(amount) DESC) AS customer_rank
    FROM
        payment
    GROUP BY
        customer_id
)
SELECT
    customer_id,
    total_spending
FROM
    CustomerSpending
WHERE
    customer_rank <= (SELECT 0.2 * COUNT(DISTINCT customer_id) + 1 FROM CustomerSpending);
    
    
    
    
    
-- Q. 08 Calculate the running total of rentals per category, ordered by rental count.
    
    WITH CategoryRentalCount AS (
    SELECT
        fc.category_id,
        COUNT(r.rental_id) AS rental_count,
        RANK() OVER (PARTITION BY fc.category_id ORDER BY COUNT(r.rental_id) DESC) AS rental_rank
    FROM
        film_category fc
    JOIN
        rental r ON fc.film_id = r.inventory_id
    GROUP BY
        fc.category_id
)
SELECT
    crc.category_id,
    crc.rental_count,
    SUM(crc.rental_count) OVER (ORDER BY crc.rental_rank) AS running_total
FROM
    CategoryRentalCount crc
ORDER BY
    crc.rental_rank;
    
    
    
    
-- Q. 09 Find the films that have been rented less than the 
-- average rental count for their respective categories.
WITH FilmRentalInfo AS (
    SELECT
        fc.film_id,
        fc.category_id,
        COUNT(r.rental_id) AS rental_count,
        AVG(COUNT(r.rental_id)) OVER (PARTITION BY fc.category_id) AS avg_rental_count
    FROM
        film_category fc
    JOIN
        rental r ON fc.film_id = r.inventory_id
    GROUP BY
        fc.film_id, fc.category_id
)
SELECT
    fri.film_id,
    fri.category_id,
    fri.rental_count,
    fri.avg_rental_count
FROM
    FilmRentalInfo fri
WHERE
    fri.rental_count < fri.avg_rental_count;
    
    
-- Q. 10 Identify the top 5 months with the highest revenue and display the revenue 
-- generated in each month.
WITH MonthlyRevenue AS (
    SELECT
        DATE_FORMAT(payment_date, '%Y-%m') AS month,
        SUM(amount) AS total_revenue
    FROM
        payment
    GROUP BY
        DATE_FORMAT(payment_date, '%Y-%m')
)
SELECT
    month,
    total_revenue
FROM
    MonthlyRevenue
ORDER BY
    total_revenue DESC
LIMIT 5;
