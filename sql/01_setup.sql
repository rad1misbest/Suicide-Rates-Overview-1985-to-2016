-- =====================================================================
-- SUICIDE RATES PROJEKT – vytvoření tabulek a nahrání dat
-- Data: WHO / Kaggle "Suicide Rates Overview 1985 to 2016" (27 820 řádků)
-- Spusť v PSQL Tool (pravý klik na databázi -> PSQL Tool) jedním řádkem:
-- \i 'cesta/k/01_setup.sql'
-- =====================================================================

SET client_encoding = 'UTF8';

DROP TABLE IF EXISTS suicides, countries, age_groups CASCADE;

-- ---------------------------------------------------------------------
-- Tabulka 1: COUNTRIES (číselník zemí -> kontinent, podle členění OSN)
-- ---------------------------------------------------------------------
CREATE TABLE countries (
    country    VARCHAR(50) PRIMARY KEY,
    continent  VARCHAR(20) NOT NULL
);

INSERT INTO countries (country, continent) VALUES
('Albania', 'Evropa'),
('Antigua and Barbuda', 'Severní Amerika'),
('Argentina', 'Jižní Amerika'),
('Armenia', 'Asie'),
('Aruba', 'Severní Amerika'),
('Australia', 'Oceánie'),
('Austria', 'Evropa'),
('Azerbaijan', 'Asie'),
('Bahamas', 'Severní Amerika'),
('Bahrain', 'Asie'),
('Barbados', 'Severní Amerika'),
('Belarus', 'Evropa'),
('Belgium', 'Evropa'),
('Belize', 'Severní Amerika'),
('Bosnia and Herzegovina', 'Evropa'),
('Brazil', 'Jižní Amerika'),
('Bulgaria', 'Evropa'),
('Cabo Verde', 'Afrika'),
('Canada', 'Severní Amerika'),
('Chile', 'Jižní Amerika'),
('Colombia', 'Jižní Amerika'),
('Costa Rica', 'Severní Amerika'),
('Croatia', 'Evropa'),
('Cuba', 'Severní Amerika'),
('Cyprus', 'Asie'),
('Czech Republic', 'Evropa'),
('Denmark', 'Evropa'),
('Dominica', 'Severní Amerika'),
('Ecuador', 'Jižní Amerika'),
('El Salvador', 'Severní Amerika'),
('Estonia', 'Evropa'),
('Fiji', 'Oceánie'),
('Finland', 'Evropa'),
('France', 'Evropa'),
('Georgia', 'Asie'),
('Germany', 'Evropa'),
('Greece', 'Evropa'),
('Grenada', 'Severní Amerika'),
('Guatemala', 'Severní Amerika'),
('Guyana', 'Jižní Amerika'),
('Hungary', 'Evropa'),
('Iceland', 'Evropa'),
('Ireland', 'Evropa'),
('Israel', 'Asie'),
('Italy', 'Evropa'),
('Jamaica', 'Severní Amerika'),
('Japan', 'Asie'),
('Kazakhstan', 'Asie'),
('Kiribati', 'Oceánie'),
('Kuwait', 'Asie'),
('Kyrgyzstan', 'Asie'),
('Latvia', 'Evropa'),
('Lithuania', 'Evropa'),
('Luxembourg', 'Evropa'),
('Macau', 'Asie'),
('Maldives', 'Asie'),
('Malta', 'Evropa'),
('Mauritius', 'Afrika'),
('Mexico', 'Severní Amerika'),
('Mongolia', 'Asie'),
('Montenegro', 'Evropa'),
('Netherlands', 'Evropa'),
('New Zealand', 'Oceánie'),
('Nicaragua', 'Severní Amerika'),
('Norway', 'Evropa'),
('Oman', 'Asie'),
('Panama', 'Severní Amerika'),
('Paraguay', 'Jižní Amerika'),
('Philippines', 'Asie'),
('Poland', 'Evropa'),
('Portugal', 'Evropa'),
('Puerto Rico', 'Severní Amerika'),
('Qatar', 'Asie'),
('Republic of Korea', 'Asie'),
('Romania', 'Evropa'),
('Russian Federation', 'Evropa'),
('Saint Kitts and Nevis', 'Severní Amerika'),
('Saint Lucia', 'Severní Amerika'),
('Saint Vincent and Grenadines', 'Severní Amerika'),
('San Marino', 'Evropa'),
('Serbia', 'Evropa'),
('Seychelles', 'Afrika'),
('Singapore', 'Asie'),
('Slovakia', 'Evropa'),
('Slovenia', 'Evropa'),
('South Africa', 'Afrika'),
('Spain', 'Evropa'),
('Sri Lanka', 'Asie'),
('Suriname', 'Jižní Amerika'),
('Sweden', 'Evropa'),
('Switzerland', 'Evropa'),
('Thailand', 'Asie'),
('Trinidad and Tobago', 'Severní Amerika'),
('Turkey', 'Asie'),
('Turkmenistan', 'Asie'),
('Ukraine', 'Evropa'),
('United Arab Emirates', 'Asie'),
('United Kingdom', 'Evropa'),
('United States', 'Severní Amerika'),
('Uruguay', 'Jižní Amerika'),
('Uzbekistan', 'Asie');

-- ---------------------------------------------------------------------
-- Tabulka 2: AGE_GROUPS (číselník věkových skupin – pořadí a český popis)
-- ---------------------------------------------------------------------
CREATE TABLE age_groups (
    age         VARCHAR(15) PRIMARY KEY,
    sort_order  INTEGER NOT NULL,
    age_label   VARCHAR(15) NOT NULL
);

INSERT INTO age_groups (age, sort_order, age_label) VALUES
('5-14 years',  1, '5–14 let'),
('15-24 years', 2, '15–24 let'),
('25-34 years', 3, '25–34 let'),
('35-54 years', 4, '35–54 let'),
('55-74 years', 5, '55–74 let'),
('75+ years',   6, '75 a více let');


-- ---------------------------------------------------------------------
-- Tabulka 3: SUICIDES (hlavní data, 1 řádek = země + rok + pohlaví + věková skupina)
-- ---------------------------------------------------------------------
CREATE TABLE suicides (
    country            VARCHAR(50) REFERENCES countries(country),
    year               INTEGER,
    sex                VARCHAR(10),      -- male / female
    age                VARCHAR(15) REFERENCES age_groups(age),
    suicides_no        INTEGER,          -- počet sebevražd
    population         INTEGER,          -- počet obyvatel ve skupině
    suicides_per_100k  NUMERIC(8,2),     -- sebevraždy na 100 000 obyvatel (za danou skupinu)
    hdi_for_year       NUMERIC(4,3),     -- index lidského rozvoje (většinou NULL!)
    gdp_for_year       BIGINT,           -- HDP země za rok v USD
    gdp_per_capita     INTEGER,          -- HDP na obyvatele v USD
    generation         VARCHAR(20),
    PRIMARY KEY (country, year, sex, age)
);

-- CSV má HDP ve formátu "2,156,624,900" (s čárkami) -> nahraje se nejdřív
-- do pomocné tabulky jako text, pak se vyčistí a vloží do suicides.
CREATE TEMP TABLE suicides_raw (
    country TEXT, year TEXT, sex TEXT, age TEXT, suicides_no TEXT,
    population TEXT, suicides_per_100k TEXT, country_year TEXT,
    hdi_for_year TEXT, gdp_for_year TEXT, gdp_per_capita TEXT, generation TEXT
);

-- Uprav cestu k CSV souboru:
\copy suicides_raw FROM 'cesta/k/master.csv' WITH (FORMAT csv, HEADER true)

INSERT INTO suicides
SELECT
    country,
    year::INTEGER,
    sex,
    age,
    suicides_no::INTEGER,
    population::INTEGER,
    suicides_per_100k::NUMERIC,
    NULLIF(hdi_for_year, '')::NUMERIC,
    REPLACE(gdp_for_year, ',', '')::BIGINT,
    gdp_per_capita::INTEGER,
    generation
FROM suicides_raw;

DROP TABLE suicides_raw;

-- Kontrola: suicides 27820, countries 101, age_groups 6
SELECT 'suicides' AS tabulka, COUNT(*) AS pocet_radku FROM suicides
UNION ALL SELECT 'countries', COUNT(*) FROM countries
UNION ALL SELECT 'age_groups', COUNT(*) FROM age_groups;
