-- Create tables in PostgreSQL
-- As we know age, height and weight have null values, 
-- for now, we shall set these as VARCHAR and not integer/numeric to avoid errors.

DROP TABLE IF EXISTS ATHLETE_EVENTS;
CREATE TABLE IF NOT EXISTS ATHLETE_EVENTS
(
id INT,
name VARCHAR,
sex VARCHAR,
age VARCHAR,
height VARCHAR,
weight VARCHAR,
team VARCHAR,
noc VARCHAR,
games VARCHAR,
year INT,
season VARCHAR,
city VARCHAR,
sport VARCHAR,
event VARCHAR,
medal VARCHAR
);
    
DROP TABLE IF EXISTS NOC_REGIONS;
CREATE TABLE IF NOT EXISTS NOC_REGIONS
(
noc VARCHAR,
region VARCHAR,
notes VARCHAR
);
