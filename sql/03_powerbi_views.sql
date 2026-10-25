-- =====================================================================
-- SUICIDE RATES – VIEW PRO POWER BI
-- Spusť v Query Tool nad stejnou databází (po 01_setup.sql).
-- View neukládají data, jen dotaz – Power BI si z nich data načte.
-- =====================================================================

DROP VIEW IF EXISTS v_pbi_data, v_cesko_sousede;

-- ---------------------------------------------------------------------
-- v_pbi_data – hlavní tabulka pro dashboard
-- 1 řádek = země + rok + pohlaví + věková skupina (stejně jako suicides)
-- Bez roku 2016 (neúplný). Záměrně BEZ sloupce suicides_per_100k –
-- míra se v Power BI počítá measurem ze součtů, ne průměrem.
-- ---------------------------------------------------------------------
CREATE VIEW v_pbi_data AS
SELECT
    s.country AS zeme,
    continent AS kontinent,
    year AS rok,
    CASE sex WHEN 'male' THEN 'Muži' ELSE 'Ženy' END AS pohlavi,
    age_label AS vekova_skupina,
    sort_order AS vek_poradi,
    suicides_no AS pocet_pripadu,
    population AS populace,
    gdp_per_capita AS hdp_na_obyvatele
FROM suicides AS s
INNER JOIN countries AS c
    ON s.country = c.country
INNER JOIN age_groups AS a
    ON s.age = a.age
WHERE year <> 2016;

-- ---------------------------------------------------------------------
-- v_cesko_sousede – výsledek úkolu 8 (1 řádek = 1 země)
-- ---------------------------------------------------------------------
CREATE VIEW v_cesko_sousede AS
WITH mira_zemi AS (
    SELECT
        country AS zeme,
        ROUND(SUM(CASE WHEN year = 1995 THEN suicides_no ELSE 0 END) * 100000.0
            / SUM(CASE WHEN year = 1995 THEN population ELSE 0 END), 1) AS mira_1995,
        ROUND(SUM(CASE WHEN year = 2014 THEN suicides_no ELSE 0 END) * 100000.0
            / SUM(CASE WHEN year = 2014 THEN population ELSE 0 END), 1) AS mira_2014
    FROM suicides
    WHERE country IN ('Czech Republic', 'Slovakia', 'Poland',
                      'Germany', 'Austria', 'Hungary')
    GROUP BY country
)
SELECT
    zeme,
    mira_1995,
    mira_2014,
    ROUND((mira_2014 - mira_1995) / mira_1995 * 100, 1) AS zmena_pct
FROM mira_zemi;

-- Kontrola: v_pbi_data 27 660 řádků, v_cesko_sousede 6 řádků
SELECT 'v_pbi_data' AS view_name, COUNT(*) AS pocet FROM v_pbi_data
UNION ALL SELECT 'v_cesko_sousede', COUNT(*) FROM v_cesko_sousede;
