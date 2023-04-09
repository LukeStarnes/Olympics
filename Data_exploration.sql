-- Lets deeper explore the data and explore the following questions:
-- Which countries are most successful?
-- Which athletes are most successful?
-- Patterns and significance of age and gender of medal winners over the years
-- Which different sports and events were the medals won?
-- Any other interesting insights

--Mention the total number of nations who participated in each Olympics game.
SELECT games, COUNT(DISTINCT(region))
FROM athlete_events
JOIN noc_regions
ON athlete_events.noc = noc_regions.noc
GROUP BY games
--Over time the number of participating countries has increased over time. Likewise for both seasons, with summer country participation higher than winter.

--Which year saw the highest and lowest no of countries participating in olympics?
WITH all_countries AS
  --Table of all games and all participating countries--
(SELECT games, region
FROM athlete_events
JOIN noc_regions
ON athlete_events.noc = noc_regions.noc
GROUP BY games, region),
tot_countries AS
  --Totals the count of countries in each game--
(SELECT games, count(*) AS total_countries
FROM all_countries
GROUP BY games)
SELECT DISTINCT
  --The FIRST_VALUE() function is a window function that returns--
  --the first value in an ordered partition of a result set--
concat(FIRST_VALUE(games) OVER(ORDER BY total_countries),' - ', 
FIRST_VALUE(total_countries) OVER(ORDER BY total_countries)) AS Lowest_participating_Countries,
concat(FIRST_VALUE(games) OVER(ORDER BY total_countries DESC),' - ',
FIRST_VALUE(total_countries) OVER(ORDER BY total_countries DESC)) AS Highest_participating_Countries
FROM tot_countries ORDER BY 1;

Which nation has participated in all of the olympic games?
WITH 
tot_games AS
(SELECT COUNT(DISTINCT games) AS total_games
from athlete_events),
countries AS
(SELECT games, region AS country
FROM athlete_events
JOIN noc_regions
ON athlete_events.noc = noc_regions.noc
GROUP BY games, region),
countries_participated AS
(SELECT country, COUNT(1) AS total_participated_games
FROM countries
GROUP BY country)    
SELECT countries_participated.*
FROM countries_participated
JOIN tot_games ON tot_games.total_games = countries_participated.total_participated_games
ORDER BY 1;

--Fetch the top 10 most successful countries in olympics. Success is defined by no of medals won.

WITH
t1 AS(
SELECT noc_regions.region, COUNT(*) AS total_medals
FROM noc_regions 
JOIN athlete_events
ON noc_regions.noc = athlete_events.noc
WHERE medal <> 'NA'
GROUP BY noc_regions.region
ORDER BY total_medals DESC
),
t2 AS(
SELECT DENSE_RANK() OVER(ORDER BY total_medals DESC) AS rank_, *
FROM t1
)
SELECT *
FROM t2
WHERE rank_ <= 10;

--List down total gold, silver and bronze medals won by each country.
  -- Enable extensions for the first time
create extension tablefunc;
SELECT region, medal, count(1)
FROM athlete_events
JOIN noc_regions 
ON athlete_events.noc = noc_regions.noc
WHERE medal <> 'NA'
GROUP BY region, medal
ORDER BY region, medal;
select country,
coalesce(gold,0) as gold,
coalesce(silver,0) as silver,
coalesce(bronze,0) as bronze
from crosstab('SELECT region, medal, count(1)
    FROM athlete_events
    JOIN noc_regions 
    ON athlete_events.noc = noc_regions.noc
    WHERE medal <> ''NA''
    GROUP BY region, medal
    ORDER BY region, medal',
    'values (''Bronze''),(''Gold''),(''Silver'')')              
as result(country varchar, bronze bigint, gold bigint, silver bigint)
order by gold desc, silver desc, bronze desc

--Identify which country won the most gold, most silver and most bronze medals in each olympic games.
  -- Enable extensions for the first time
  --create extension tablefunc;
with temp1 as
(
select substring(games_country, 1, position(' - ' in games_country) - 1) as games,
substring(games_country, position(' - ' in games_country) + 3) as country,
coalesce(gold,0) as gold,
coalesce(silver,0) as silver,
coalesce(bronze,0) as bronze
from crosstab('SELECT concat(games,'' - '',region) as games_country, medal, count(1)
    FROM athlete_events
    JOIN noc_regions 
    ON athlete_events.noc = noc_regions.noc
    WHERE medal <> ''NA''
    GROUP BY games, region, medal
    ORDER BY games, region, medal',
    'values (''Bronze''),(''Gold''),(''Silver'')')              
as result(games_country varchar, bronze bigint, gold bigint, silver bigint)
order by games_country
 )
select distinct games
, concat(first_value(country) over(partition by games order by gold desc)
         , ' - ' , first_value(gold) over(partition by games order by gold desc)) as gold
, concat(first_value(country) over(partition by games order by silver desc)
         , ' - ' , first_value(silver) over(partition by games order by silver desc)) as silver
, concat(first_value(country) over(partition by games order by bronze desc)
         , ' - ' , first_value(bronze) over(partition by games order by bronze desc)) as bronze
from temp1 
order by games
 
--Which countries have never won gold medal but have won silver/bronze medals?
--To do

--Fetch details of the oldest athletes to win a gold medal.
SELECT name,age,team,games,sport,medal
FROM athlete_events
where medal = 'Gold' AND NOT age = 'NA'
ORDER BY age DESC
LIMIT 10

--Fetch details of the youngest athletes to win a gold medal.
SELECT name,age,team,games,sport,medal
FROM athlete_events
where medal = 'Gold' AND NOT age = 'NA'
ORDER BY age ASC
LIMIT 10

--Find the Ratio of male and female athletes participated in all olympic games.
WITH 
IdPerGame AS
(Select distinct(id),sex,games FROM athlete_events
 order by id
),
TFemale AS
(SELECT DISTINCT(games), count(sex) AS Female_Athletes
from IdPerGame
WHERE sex = 'F'
GROUP BY DISTINCT(games)),
TMale AS
(
SELECT DISTINCT(games), count(sex) AS Male_Athletes
from IdPerGame
WHERE sex = 'M'
GROUP BY DISTINCT(games)
),
TBoth AS
(SELECT *
FROM Tmale
LEFT JOIN Tfemale
ON Tmale.games = Tfemale.games)
SELECT *, 
CONCAT('1 : ' ,CAST(Male_athletes/CAST((FEmale_athletes) AS DECIMAL(7,2)) AS DECIMAL(6,1)))
AS "Female:Male" FROM TBoth

--Fetch the athletes who have won the most gold medals.
With Golds AS (SELECT * FROM athlete_events
WHERE medal = 'Gold')
SELECT Golds.name, COUNT(medal)
FROM Golds
Group by Golds.name
ORDER BY count DESC

--Fetch the top 5 athletes who have won the most medals (gold/silver/bronze)
With Medals AS (SELECT * FROM athlete_events
WHERE not medal = 'NA')
SELECT Medals.name, COUNT(medal)
FROM Medals
Group by Medals.name
ORDER BY count Desc

--Identify the sport which was played in all summer Olympics
WITH t1 AS
(SELECT COUNT(DISTINCT(games)) AS Total_num_sum_games
FROM athlete_events
WHERE season = 'Summer'),
t2 AS
(SELECT sport, count(distinct(games)) AS num_of_games_per_sport
FROM athlete_events
WHERE season = 'Summer'
GROUP BY sport
ORDER BY count(distinct(games))DESC)
SELECT * FROM t2
JOIN t1 ON t1.Total_num_sum_games = t2.num_of_games_per_sport

--Which Sports were just played only once in the olympics?
WITH t1 AS
(SELECT sport, COUNT(DISTINCT(games))
FROM athlete_events
GROUP BY sport
HAVING COUNT(DISTINCT(games)) = 1),
t2 AS
(SELECT sport, games
FROM athlete_events)
SELECT distinct(t1.sport), t2.games
FROM t1
JOIN t2
ON t1.sport = t2.sport

--Fetch the total no of sports played in each olympic games.
SELECT games, count(distinct(sport)) AS total_sports_played
FROM athlete_events
group by games
ORDER BY total_sports_played DESC, games

