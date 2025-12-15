CREATE DATABASE Streamlytics;
USE Streamlytics;



CREATE TABLE Movies (
movie_id INT AUTO_INCREMENT PRIMARY KEY,
title varchar(50) NOT NULL,
genre VARCHAR(20),
duration_mins INT CHECK(duration_mins>0),
released_year YEAR );

SELECT * FROM movies;



CREATE TABLE subscriptions(
subscription_id INT AUTO_INCREMENT PRIMARY KEY,
plan_name VARCHAR(20) NOT NULL,
price DECIMAL(10,2) NOT NULL,
no_of_month INT);

SELECT * FROM subscriptions;



CREATE TABLE users(
user_id INT AUTO_INCREMENT PRIMARY KEY,
name VARCHAR(50) NOT NULL,
email_id VARCHAR(100) UNIQUE NOT NULL,
subscription_id INT,
join_date DATE,
FOREIGN KEY (subscription_id) REFERENCES subscriptions(subscription_id));

SELECT * FROM users;



CREATE TABLE watch_history(
history_id INT AUTO_INCREMENT PRIMARY KEY,
user_id INT,
movie_id INT,
watch_date DATE,
watch_time_mins INT CHECK(watch_time_mins > 0),
FOREIGN KEY (user_id) REFERENCES users(user_id),
FOREIGN KEY (movie_id) REFERENCES movies(movie_id));

SELECT * FROM watch_history;



CREATE TABLE ratings(
rating_id INT AUTO_INCREMENT PRIMARY KEY,
user_id INT,
movie_id INT,
rating DECIMAL(2,1) CHECK(rating BETWEEN 1 AND 5),
rating_date DATE,
FOREIGN KEY (user_id) REFERENCES users(user_id),
FOREIGN KEY (movie_id) REFERENCES movies(movie_id));

SELECT * FROM subscriptions;


DESC subscriptions;

SELECT COUNT(*) FROM movies;

-- ---------------------------------------------------------------------------------------------------------------------------
-- ---------------------------------------------------------------------------------------------------------------------------
-- REVENUE 
-- USER ENGAGEMENT
-- MOVIES


-- MOVIES

-- 1] TOTAL NO. OF MOIVES
SELECT COUNT(*) AS Total_No_of_Movies FROM movies;


-- 2] TOTAL NO. OF MOVIES RELEASED IN EACH YEAR
SELECT Released_Year, COUNT(movie_id) AS Total_Movies
FROM movies
GROUP BY released_year
ORDER BY released_year;


-- 3] TOTAL NO. OF MOVIES IN EACH GENRE
SELECT Genre, COUNT(movie_id) AS Total_Movies
FROM movies
GROUP BY genre
ORDER BY total_movies DESC;


-- 4] RETRIEVE TOTAL MOVIES RELEASED IN EACH GENRE COMPARING WITH TOTAL MOVIES RELEASED IN A SPECIFIC YEAR (EX: YEAR-2014)
SELECT Genre, COUNT(movie_id) AS Movies_in_Genre,
	(SELECT COUNT(*) FROM Movies 
     WHERE released_year = 2014) AS Total_Movies
FROM movies
WHERE released_year = 2014
GROUP BY genre
ORDER BY movies_in_genre DESC;


-- 5] LIST ALL MOVIES IN A SPECIFIC GENRE (EX: GENRE-ACTION)
SELECT Title, Released_Year, Duration_mins
FROM movies
WHERE genre = 'Action'
ORDER BY released_year;


-- 6] TOP 5 MOVIES BY AVG_RATING
SELECT m.Title, m.Genre, ROUND(AVG(r.rating),1) AS Avg_Rating 
FROM movies m INNER JOIN ratings r 
ON m.movie_id=r.movie_id
GROUP BY m.title, m.genre
ORDER BY Avg_Rating DESC
LIMIT 5;


-- 7] TOP 5 MOVIES BY TOTAL_WATCH_TIME 
SELECT m.Title, m.Genre, SUM(w.watch_time_mins) AS Total_Watch_Time
FROM movies m INNER JOIN watch_history w 
ON m.movie_id=w.movie_id
GROUP BY m.title, m.genre
ORDER BY TOtal_Watch_Time DESC
LIMIT 5;


-- 8] LIST THE MOVIES THAT ARE BELOW AVG AND COUNT OF USER WHO WATCH THEM.
SELECT m.Movie_id, m.Title, ROUND(AVG(r.rating),1) AS No_Ratings, 
COUNT(r.rating_id) AS Count_of_user
FROM movies m LEFT JOIN ratings r 
ON m.movie_id=r.movie_id
GROUP BY m.title, m.movie_id
HAVING NO_Ratings < (SELECT AVG(r.rating) FROM ratings r)
ORDER BY count_of_user;


-- 9] SHOW THE LEAST 10 WATCHED MOVIES BY WATCH_TIME
SELECT m.Title, m.Genre, m.Duration_mins, 
SUM(w.watch_time_mins) AS "Total_Watched_Time(mins)" 
FROM movies m LEFT JOIN watch_history w 
ON m.movie_id=w.movie_id
GROUP BY m.title, m.genre, m.duration_mins
ORDER BY SUM(w.watch_time_mins)
LIMIT 10;


-- 10] TOP RATED MOVIE FROM EACH YEAR
SELECT Released_Year, title AS Top_Rated_Movie, Avg_Rating
FROM 
(SELECT m.released_year, m.title,
	ROUND(AVG(r.rating), 1) AS avg_rating,
	ROW_NUMBER() 
    OVER (PARTITION BY m.released_year ORDER BY AVG(r.rating) DESC) AS rn
FROM movies m JOIN ratings r 
ON m.movie_id = r.movie_id
GROUP BY m.released_year, m.title) AS ranked
WHERE rn = 1;


-- 11] MOST WATCHED MOVIE FROM EACH YEAR
SELECT Year_Released, title AS Most_Watched_Movie, Watch_Count
FROM 
(SELECT m.released_year AS year_released,m.title,
	COUNT(w.history_id) AS watch_count,
	ROW_NUMBER() 
    OVER (PARTITION BY m.released_year ORDER BY COUNT(w.history_id) DESC) AS rn
FROM movies m JOIN watch_history w 
ON m.movie_id = w.movie_id
GROUP BY m.released_year, m.title) AS ranked
WHERE rn = 1;


-- 12] TOP RATED MOVIE BY EACH GENRE
SELECT Genre, title AS Top_Rated_Movies, Avg_Rating
FROM 
(SELECT m.genre, m.title,
	ROUND(AVG(r.rating), 2) AS avg_rating,
	ROW_NUMBER() 
    OVER (PARTITION BY m.genre ORDER BY AVG(r.rating) DESC) AS rn
FROM Movies m JOIN Ratings r 
ON m.movie_id = r.movie_id
GROUP BY m.genre, m.title) AS ranked
WHERE rn = 1;


-- 13] MOST WATCHED MOVIE FROM EACH GENRE
SELECT Genre, title AS Most_Watched_Movie, Watch_Count
FROM 
(SELECT m.genre, m.title,
	COUNT(w.history_id) AS watch_count,
	ROW_NUMBER() 
    OVER (PARTITION BY m.genre ORDER BY COUNT(w.history_id) DESC) AS rn
FROM Movies m JOIN Watch_History w 
ON m.movie_id = w.movie_id
GROUP BY m.genre, m.title) AS ranked
WHERE rn = 1;


-- -----------------------------------------------------------------------------------------------------

-- USER ENGAGEMENT

-- 1] USERS WHO HAVE WATCHED MOVIES IN MULTIPLE GENRE WITH GENRES
SELECT u.User_ID, u.Name,
GROUP_CONCAT(DISTINCT m.genre ORDER BY m.genre) AS Genres_Watched
FROM users u
JOIN watch_history w ON u.user_id = w.user_id
JOIN Movies m ON w.movie_id = m.movie_id
GROUP BY u.user_id, u.name
HAVING COUNT(DISTINCT m.genre) > 1;


-- 2] USERS WITH "WATCHED AND RATED MOVIE'S GENRE" AND "WATCHED AND NON-RATED MOVIES'S GENRE"
SELECT 
    u.User_ID,
    u.Name,
    GROUP_CONCAT(DISTINCT CASE WHEN r.rating_id IS NOT NULL THEN m.genre END) AS Watched_and_Rated_Genres,
    GROUP_CONCAT(DISTINCT CASE WHEN r.rating_id IS NULL THEN m.genre END) AS Watched_and_not_Rated_Genres
FROM users u
JOIN watch_history w ON u.user_id = w.user_id
JOIN movies m ON w.movie_id = m.movie_id
LEFT JOIN Ratings r ON u.user_id = r.user_id AND m.movie_id = r.movie_id
GROUP BY u.user_id, u.name
ORDER BY u.user_id;


-- 3] CALCULATE EACH USER'S TOTAL_WATCH_TIME COMPARING WITH AVG_WATCH_TIME OF ALL USERS
SELECT u.User_ID, u.Name,
SUM(w.watch_time_mins) AS Total_Watch_Time,
ROUND(AVG(SUM(w.watch_time_mins)) 
OVER (), 2) AS 'Total_Avg_Watch_Time'
FROM users u
JOIN watch_history w ON u.user_id = w.user_id
GROUP BY u.user_id, u.name;


-- 4] DISPLAY TOTAL WATCH_SESSION EACH YEAR
SELECT YEAR(watch_date) AS Year, 
COUNT(*) AS Total_Watch_Session
FROM watch_history
GROUP BY Year
ORDER BY Year;


-- 5] DISPLAY TOTAL USERS JOINED EACH YEAR
SELECT YEAR(join_date) AS Year,
COUNT(*) AS Total_Users_joined
FROM users
GROUP BY year
ORDER BY Year;

-- ---------------------------------------------------------------------------------------

-- SUBSCRIPTION/TOTAL REVENUE

-- 1] ACTIVE USERS IN EACH SUBSCRIPTION PLAN
SELECT s.plan_name AS Subscription_Plan,
COUNT(u.user_id) AS Active_Users
FROM users u JOIN subscriptions s 
ON u.subscription_id = s.subscription_id
WHERE CURRENT_DATE 
BETWEEN u.join_date AND DATE_ADD(u.join_date, INTERVAL s.no_of_month MONTH)
GROUP BY s.plan_name
ORDER BY active_users DESC;


-- 2] MOST USED SUBSCRIPTION PLAN
SELECT s.plan_name AS Subscription_Plan, COUNT(u.user_id) AS User_Count
FROM subscriptions s
JOIN users u ON s.subscription_id = u.subscription_id
GROUP BY s.plan_name
ORDER BY user_count DESC;


-- 3] TOTAL REVENUE GENERATED FROM SUBSCRIPTIONS
SELECT SUM(s.price) AS Total_Revenue
FROM subscriptions s
JOIN users u ON s.subscription_id = u.subscription_id;


-- 4] TOTAL REVENUE GENERATED PER YEAR FROM SUBSCRIPTIONS 
SELECT YEAR(u.join_date) AS Year,
SUM(s.price) AS Revenue
FROM subscriptions s
JOIN users u ON s.subscription_id = u.subscription_id
GROUP BY YEAR(u.join_date)
ORDER BY year;


-- 5] TOTAL REVENUE GENERATED FROM EACH SUBSCRIPTION PLAN IN RS AND PERCENTAGE 
SELECT s.plan_name AS Subscription_Plan,
(COUNT(u.user_id) * s.price) AS Revenue,
ROUND(((COUNT(u.user_id)*s.price)*100.0) / SUM(COUNT(u.user_id)*s.price) 
OVER (), 2) AS Percentage_Contribution
FROM subscriptions s
JOIN users u ON s.subscription_id = u.subscription_id
GROUP BY s.subscription_id, s.plan_name, s.price
ORDER BY revenue DESC;



