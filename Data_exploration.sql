-- Lets deeper explore the data and explroe the following questions:
-- Which countries are most successful?
-- Which athletes are most successful?
-- Patterns and significance of age and gender of medal winners over the years
-- Which different sports and events were the medals won?
-- Any other interesting insights

SELECT games, COUNT(DISTINCT(region))
FROM athlete_events
JOIN noc_regions
ON athlete_events.noc = noc_regions.noc
GROUP BY games
