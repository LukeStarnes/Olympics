--Let’s check, verify and clean where necessary the columns of our data using SQL queries

--ATHLETE ID / NAME
SELECT COUNT(*) AS number_of_athlete_records
FROM athlete_events
--271,116 records is expected.

SELECT COUNT(DISTINCT(id)) AS distinct_athletes
FROM athlete_events
--Each athlete is assigned a unique id. There are less ids than records as each athlete can complete in different events or games. We can see that on average over the whole history of the Olympic games, each athlete on average competed if two different events.

SELECT id, name, COUNT(*) AS total_entries
FROM athlete_events
GROUP BY id, name
ORDER BY total_entries DESC
--Here we can see the id and names of the top 10 athletes by number of entries in different events over the history of the Olympics.

SELECT id, team, games, event, count(*)
FROM athlete_events
GROUP BY games, id, team, event
HAVING id = 77710
--Looking into the athlete with the most entries (58) we can see a breakdown. 44 of these entries were in the 1932 Summer games for Art Competitions – Sculpturing, with 1 being a medal winner. Depending on how the data is looked at, these could be classified as duplicates. It seems multiple entries by the same athlete were allowed in Art Competitions when they were in the Olympics.

--SEX
SELECT sex, count(*) as records
from athlete_events
Group by sex
--Checking the sex column. No nulls, every athlete assigned ‘M’ or ‘F’, with male entries being significantly higher.

--AGE
SELECT min(age) AS min_age, max(age) AS max_age
from athlete_events
WHERE age <> 'NA'
--Not accounting for the 9474 null age records, the athlete age range is between 10 and 97. Surprising, but possible.

SELECT id, name, age, games, event 
from athlete_events
ORDER BY age
LIMIT 1
--This is the record of the youngest participant at 10 years

SELECT id, name, age, games, event 
from athlete_events
WHERE age <> 'NA'
ORDER BY age DESC
LIMIT 1
--This is the record of the oldest participant at 97 years. Although on further investigation, John Quincy Adams Ward died in 1910 at the age of 79. Thus his art was entered posthumous and the age is number of years since birth. There are more occurrences of cases like these for the arts competitions and therefore it might be a good idea to exclude them from the analysis.

with t1 as (
SELECT * from athlete_events 
WHERE age = 'NA' AND medal <> 'NA'
ORDER BY year desc)
SELECT
    case when year >= 1960 then '1960+'
         when year >= 1940 and year < 1960 then '1940 - 1959'
         when year >= 1920 and year < 1940 then '1920 - 1939'
         when year >= 1896 and year < 1920 then '1896 - 1919'
         else 'invalid'
    end Year_Range,
    count(*) as TotalWithinRange
from t1
group by 1
-- Here we investigate the medal winners with Null ages (Most of these date pre-1960)

--GAMES
SELECT year, city, games, count(*) AS entries
FROM athlete_events
GROUP BY year, city, games
ORDER BY year, games
--52 games over the 120 years.

--YEAR
select min(year), max(year)
from athlete_events
-- As expected, the range of the years of the games are from 1896 - 2016

--SEASON
SELECT season, count(*) 
FROM athlete_events
GROUP BY season
--Season is Summer or Winter, with summer having significantly more athlete entries.

--CITY
with t1 AS (SELECT year, city, games, count(*) AS entries
FROM athlete_events
GROUP BY year, city, games
ORDER BY year, games)
SELECT city, count(*) AS games_hosted
FROM t1
GROUP BY city
HAVING count(*) > 1
ORDER BY games_hosted DESC
--8 cities have hosted more then one game

--SPORT
SELECT sport, count(*) 
FROM athlete_events
GROUP BY sport
ORDER BY count(*) ASC
LIMIT 10
--Some interesting sports with few athlete entries, most are historic

--EVENT
SELECT sport, event, count(*) 
FROM athlete_events
GROUP BY sport, event
ORDER BY sport, event
--Some interesting sport and events, 66 sports further categorised into 765 events

--REGION/COUNTRY
with t1 as
(SELECT athlete_events.noc, region AS country  
from athlete_events
FULL JOIN noc_regions
ON athlete_events.noc = noc_regions.noc)
SELECT noc, count(*) from t1
GROUP BY noc, country
HAVING country ISNULL
--Investigating the null regions identified earlier, it is found that the noc in the athlete_event table for Singapore is ‘SGP’ but input as ‘SIN’ in the noc_regions table, therefore when the tables are joined, Singapore is not recognised as a country and is left as null. This can be changed by changing the incorrect ‘SIN’ noc in the noc_regions table to ‘SGP’

--Addressing the other nulls:
with t1 as
(SELECT athlete_events.noc, athlete_events.team, athlete_events.medal, region AS country  
from athlete_events
FULL JOIN noc_regions
ON athlete_events.noc = noc_regions.noc)
SELECT noc, team, country, medal, count(*) from t1
GROUP BY noc, team, country, medal
having country = 'NA'
--So from the 370 country null values identified earlier in python:
--349: Fixed (Singapore)
--And the following with NA countries which can be left as they are not medal winners and will not be relevant for final analysis.
--12: Refugee Olympic Athletes
--7: Tuvalu
--2: Unknown

--MEDAL
SELECT medal, count(*) 
from athlete_events
GROUP BY medal
ORDER BY count(*)
--The medal column is as expected, every row is either a medal winner (Bronze, Silver, Gold) or non medal winner (NA)

--DELIVERABLE: A cleaned excel sheet saved as ‘Olympic_medal_winners’ with just medal winning rows in:
SELECT id AS athlete_id, name, sex, age, height, weight, games, year, season, city, sport, event, region AS country, medal  
from athlete_events
FULL JOIN noc_regions
ON athlete_events.noc = noc_regions.noc
WHERE medal <> 'NA'
