/*
Question #1: 
Return the percentage of users who have posted more than 10 times rounded to 3 decimals.

Expected column names: more_than_10_posts
*/

-- q1 solution:

WITH more_than_10 AS (SELECT user_id
						FROM posts
						GROUP BY user_id
						HAVING COUNT(post_id) > 10)

SELECT  ROUND(CAST(CAST(COUNT(DISTINCT m.user_id) AS float)/
                   COUNT(DISTINCT p.user_id) AS numeric), 3) 
                   AS more_than_10_posts
FROM posts p
LEFT JOIN more_than_10 m
ON p.user_id = m.user_id;

/*
Question #2: 
Recommend posts to user 888 by finding posts liked by users who have liked a post user 888 has also liked more than one time. 


The output should adhere to the following requirements: 


User 888 should not be recommend posts that they have already liked.
Of the posts that meet the criteria above, return only the three most popular posts (by number of likes). 
Return the post_ids in descending order.

Expected column names: post_id

*/

-- q2 solution:

SELECT post_id
FROM likes
WHERE user_id IN(SELECT user_id FROM likes WHERE post_id IN 
                 (SELECT post_id FROM likes WHERE user_id = 888) 
		    		AND user_id != 888)
GROUP BY post_id
HAVING COUNT(user_id) > 1
ORDER BY post_id DESC
LIMIT 3;


/*
Question #3: 
Vibestream wants to track engagement at the user level. When a user makes their first post, the team wants to begin tracking the cumulative sum of posts over time for the user.

Return a table showing the date and the total number of posts user 888 has made to date. The time series should begin at the date of 888’s first post and end at the last available date in the posts table.


Expected column names: post_date, posts_made

*/

-- q3 solution:

WITH generatedate AS (SELECT CAST(generate_series(MIN(post_date), MAX(post_date), '1day'::interval) AS date) post_date
						FROM posts
						WHERE user_id = 888)


SELECT 	g.post_date, 
				COALESCE(SUM(p.post_count) OVER (ORDER BY p.post_date), 0) post_made
FROM generatedate g
LEFT JOIN (SELECT post_date, COUNT(post_id) post_count 
           FROM posts WHERE user_id = 888 GROUP BY post_date) AS p
ON g.post_date = p.post_date
ORDER BY post_made;

/*
Question #4: 
The Vibestream feed algorithm updates with user preferences every day. Every update is independent of the previous update. Sometimes the update fails because Vibestreams systems are unreliable. 

Write a query to return the update state for each continuous interval of days in the period from 2023-01-01 to 2023-12-30.

the algo_update is 'failed' if tasks in a date interval failed and 'succeeded' if tasks in a date interval succeeded. every interval has a  start_dateand an end_date.


Return the result in ascending order by start_date.


Expected column names: algo_update, start_date, end_date
*/

-- q4 solution:

SELECT (CASE WHEN success_date IS NOT NULL THEN 'succeeded' WHEN fail_date IS NOT NULL THEN 'failed' END) AS algo_update,
				COALESCE(f.fail_date, s.success_date) start_date,
				COALESCE(s.success_date, LEAD(f.fail_date) OVER(), f.fail_date) end_date
    
FROM (SELECT success_date FROM algo_update_success WHERE success_date BETWEEN '2023-01-01' AND '2023-12-30') s
FULL JOIN  (SELECT fail_date FROM algo_update_failure WHERE fail_date BETWEEN '2023-01-01' AND '2023-12-30') f
ON s.success_date = f.fail_date;

