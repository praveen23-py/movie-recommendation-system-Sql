USE imdb;
select * from movie;
select * from names;
select * from ratings;
select * from role_mapping;
select * from genre;
select * from director_mapping;
 -- Which columns in the 'movie' table have null values?
 SELECT 
    COUNT(CASE
        WHEN title IS NULL THEN id
    END) AS title_nulls,
    COUNT(CASE
        WHEN year IS NULL THEN id
    END) AS year_nulls,
    COUNT(CASE
        WHEN date_published IS NULL THEN id
    END) AS date_published_nulls,
    COUNT(CASE
        WHEN duration IS NULL THEN id
    END) AS duration_nulls,
    COUNT(CASE
        WHEN country IS NULL THEN id
    END) AS country_nulls,
    COUNT(CASE
        WHEN worlwide_gross_income IS NULL THEN id
    END) AS worlwide_gross_income_nulls,
    COUNT(CASE
        WHEN languages IS NULL THEN id
    END) AS languages_nulls,
    COUNT(CASE
        WHEN production_company IS NULL THEN id
    END) AS production_company_nulls
FROM
    movie;
    --  Find the total number of movies released in each year. How does the trend look month-wise?
    -- part 1
    SELECT 
    year, COUNT(*) AS number_of_movies
FROM
    movie
GROUP BY year;
-- part 2
SELECT 
    MONTH(date_published) as month_num, COUNT(*) AS number_of_movies
FROM
    movie
GROUP BY month_num
ORDER BY month_num;
-- How many movies were produced in the USA or India in the year 2019?
SELECT 
    COUNT(*) AS number_of_movies
FROM
    movie
WHERE year=2019 AND (country LIKE '%USA%' or country LIKE '%India%');
-- Find the unique list of the genres present in the data set?
SELECT DISTINCT
    genre
FROM
    genre;
    -- Which genre had the highest number of movies produced overall?
    SELECT 
    genre,
    COUNT(movie_id) as movie_count
FROM
    genre
GROUP BY genre
ORDER BY movie_count DESC
LIMIT 1;
-- How many movies belong to only one genre?
WITH movie_genre_summary AS
(
SELECT 
	movie_id,
	COUNT(genre) AS genre_count
FROM
	genre
GROUP BY movie_id
)
SELECT 
    COUNT(DISTINCT movie_id) AS single_genre_movie_count
FROM
    movie_genre_summary
WHERE
    genre_count=1;
-- What is the average duration of movies in each genre? 
SELECT 
    genre,
    AVG(duration) AS avg_duration
FROM
    genre AS g
        LEFT JOIN
    movie AS m 
		ON g.movie_id = m.id
GROUP BY genre;
-- What is the rank of the ‘thriller’ genre of movies among all the genres in terms of number of movies produced? 
WITH summary AS
(
	SELECT 
		genre,
		COUNT(movie_id) AS movie_count,
		RANK () OVER (ORDER BY COUNT(movie_id) DESC) AS genre_rank
	FROM
		genre
	GROUP BY genre
)
SELECT 
    *
FROM
    summary
WHERE
    lower(genre) = 'thriller';
--  Find the minimum and maximum values for each column of the 'ratings' table except the movie_id column.
SELECT 
    MIN(avg_rating) AS min_avg_rating,
    MAX(avg_rating) AS max_avg_rating,
    MIN(total_votes) AS min_total_votes,
    MAX(total_votes) AS max_total_votes,
    MIN(median_rating) AS min_median_rating,
    MAX(median_rating) AS max_median_rating
FROM
    ratings;
--  What are the top 10 movies based on average rating?
    WITH top_movies AS
(
SELECT 
    m.title,
    avg_rating,
    ROW_NUMBER() OVER (ORDER BY avg_rating DESC) AS movie_rank
FROM
    movie AS m
        LEFT JOIN
    ratings AS r ON m.id = r.movie_id
)
SELECT 
    *
FROM
    top_movies
WHERE
    movie_rank <= 10;
 -- Summarise the ratings table based on the movie counts by median ratings
 SELECT 
    median_rating, COUNT(movie_id) AS movie_count
FROM
    ratings
GROUP BY median_rating
ORDER BY median_rating;
-- Which production house has produced the most number of hit movies (average rating > 8)?
   WITH top_prod AS
(
SELECT 
    m.production_company,
    COUNT(m.id) AS movie_count,
    ROW_NUMBER() OVER (ORDER BY COUNT(m.id) DESC) AS prod_company_rank
FROM
    movie AS m
        LEFT JOIN
    ratings AS r
		ON m.id = r.movie_id
WHERE avg_rating>8 AND m.production_company IS NOT NULL
GROUP BY m.production_company
)
SELECT 
    *
FROM
    top_prod
WHERE
    prod_company_rank = 1; 
-- How many movies released in each genre in March 2017 in the USA had more than 1,000 votes?
SELECT 
    genre, 
    COUNT(g.movie_id) AS movie_count
FROM
    genre AS g
        INNER JOIN
    movie AS m 
		ON g.movie_id = m.id
			INNER JOIN
		ratings AS r 
			ON m.id = r.movie_id
WHERE
    year = 2017
        AND MONTH(date_published) = 3
        AND LOWER(country) LIKE '%usa%'
        AND total_votes > 1000
GROUP BY genre
ORDER BY movie_count DESC;
 -- Do German movies get more votes than Italian movies? 
 WITH votes_summary AS
(
SELECT 
	COUNT(CASE WHEN LOWER(m.languages) LIKE '%german%' THEN m.id END) AS german_movie_count,
	COUNT(CASE WHEN LOWER(m.languages) LIKE '%italian%' THEN m.id END) AS italian_movie_count,
	SUM(CASE WHEN LOWER(m.languages) LIKE '%german%' THEN r.total_votes END) AS german_movie_votes,
	SUM(CASE WHEN LOWER(m.languages) LIKE '%italian%' THEN r.total_votes END) AS italian_movie_votes
FROM
    movie AS m 
	    INNER JOIN
	ratings AS r 
		ON m.id = r.movie_id
)
SELECT 
    ROUND(german_movie_votes / german_movie_count, 2) AS german_votes_per_movie,
    ROUND(italian_movie_votes / italian_movie_count, 2) AS italian_votes_per_movie
FROM
    votes_summary;
--  Find the number of null values in each column of the 'names' table, except for the 'id' column.
SELECT 
    COUNT(CASE
        WHEN name IS NULL THEN id
    END) AS name_nulls,
    COUNT(CASE
        WHEN height IS NULL THEN id
    END) AS height_nulls,
    COUNT(CASE
        WHEN date_of_birth IS NULL THEN id
    END) AS date_of_birth_nulls,
    COUNT(CASE
        WHEN known_for_movies IS NULL THEN id
    END) AS known_for_movies_nulls
FROM
    names;
-- Who are the top two actors whose movies have a median rating >= 8?
SELECT 
	n.name as actor_name,
	COUNT(m.id) AS movie_count
FROM
	names AS n
		INNER JOIN
	role_mapping AS a
		ON n.id=a.name_id
			INNER JOIN
        movie AS m
			ON a.movie_id = m.id
				INNER JOIN
            ratings AS r
				ON m.id=r.movie_id
WHERE median_rating>=8 AND category = 'actor'
GROUP BY actor_name
ORDER BY movie_count DESC
LIMIT 2;
--  Which are the top three production houses based on the number of votes received by their movies?
WITH top_prod AS
(
SELECT 
    m.production_company,
    SUM(r.total_votes) AS vote_count,
    ROW_NUMBER() OVER (ORDER BY SUM(r.total_votes) DESC) AS prod_company_rank
FROM
    movie AS m
        LEFT JOIN
    ratings AS r
		ON m.id = r.movie_id
WHERE m.production_company IS NOT NULL
GROUP BY m.production_company
)
SELECT 
    *
FROM
    top_prod
WHERE
    prod_company_rank <= 3;
-- What is the genre-wise running total and moving average of the average movie duration? 
WITH genre_summary AS
(
SELECT 
    genre,
    ROUND(AVG(duration),2) AS avg_duration
FROM
    genre AS g
        LEFT JOIN
    movie AS m 
		ON g.movie_id = m.id
GROUP BY genre
)
SELECT *,
	SUM(avg_duration) OVER (ORDER BY genre ROWS UNBOUNDED PRECEDING) AS running_total_duration,
    AVG(avg_duration) OVER (ORDER BY genre ROWS UNBOUNDED PRECEDING) AS moving_avg_duration
FROM
	genre_summary;
/*  Get the following details for top 9 directors (based on number of movies):

Director id
Name
Number of movies
Average inter movie duration in days
Average movie ratings
Total votes
Min rating
Max rating
Total movie duration */
WITH top_directors AS
(
SELECT 
	n.id as director_id,
    n.name as director_name,
	COUNT(m.id) AS movie_count,
    RANK() OVER (ORDER BY COUNT(m.id) DESC) as director_rank
FROM
	names AS n
		INNER JOIN
	director_mapping AS d
		ON n.id=d.name_id
			INNER JOIN
        movie AS m
			ON d.movie_id = m.id
GROUP BY n.id
),
movie_summary AS
(
SELECT
	n.id as director_id,
    n.name as director_name,
    m.id AS movie_id,
    m.date_published,
	r.avg_rating,
    r.total_votes,
    m.duration,
    LEAD(date_published) OVER (PARTITION BY n.id ORDER BY m.date_published) AS next_date_published,
    DATEDIFF(LEAD(date_published) OVER (PARTITION BY n.id ORDER BY m.date_published),date_published) AS inter_movie_days
FROM
	names AS n
		INNER JOIN
	director_mapping AS d
		ON n.id=d.name_id
			INNER JOIN
        movie AS m
			ON d.movie_id = m.id
				INNER JOIN
            ratings AS r
				ON m.id=r.movie_id
WHERE n.id IN (SELECT director_id FROM top_directors WHERE director_rank<=9)
)
SELECT 
	director_id,
	director_name,
	COUNT(DISTINCT movie_id) as number_of_movies,
	ROUND(AVG(inter_movie_days),0) AS avg_inter_movie_days,
	ROUND(
	SUM(avg_rating*total_votes)
	/
	SUM(total_votes)
		,2) AS avg_rating,
    SUM(total_votes) AS total_votes,
    MIN(avg_rating) AS min_rating,
    MAX(avg_rating) AS max_rating,
    SUM(duration) AS total_duration
FROM 
movie_summary
GROUP BY director_id
ORDER BY number_of_movies DESC, avg_rating DESC;
    

    
