-- =====================================================================
-- SUICIDE RATES 1985–2016 – ANALÝZA V SQL
-- Autor: Radim Soldan
-- Nástroje: PostgreSQL 17, pgAdmin 4
-- Data: WHO / Kaggle „Suicide Rates Overview 1985 to 2016“
--       27 820 řádků, 101 zemí; 1 řádek = země + rok + pohlaví + věková skupina
--
-- Tabulky (vytvoří 01_setup.sql):
--   suicides   – hlavní data
--   countries  – číselník země → kontinent (dle členění OSN, vytvořen ručně)
--   age_groups – číselník věkových skupin (pořadí + český popis, vytvořen ručně)
--
-- Metodika:
--   Míra na 100 000 obyvatel se všude počítá ze součtů
--   SUM(suicides_no) * 100000.0 / SUM(population), nikoli průměrem sloupce
--   suicides_per_100k – skupiny mají různě velkou populaci a průměr by
--   výsledek zkreslil.
--
-- Použité techniky: agregace, GROUP BY / HAVING, poddotaz, INNER JOIN
--   s číselníky, řazení přes pořadový sloupec, podmíněná agregace
--   SUM(CASE …), CTE, procentuální změna, kontrola kvality dat.
--
-- Omezení dat:
--   * Rok 2016 obsahuje jen 16 zemí (ostatní roky 48–89) → z časových
--     analýz je vyřazen.
--   * Počet zemí se mezi roky mění, takže celosvětový trend je částečně
--     ovlivněn tím, které země v daném roce data poskytly.
--   * V datech chybí např. Čína a Indie, Afriku zastupují jen 4 země.
--   * Sloupec hdi_for_year je ze 70 % prázdný, proto se nepoužívá.
--   * Data ukazují souvislosti, nikoli příčiny.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1) ROZSAH DAT
-- Kolik zemí a jaké období dataset pokrývá a kolik případů obsahuje?
-- ---------------------------------------------------------------------
SELECT
    COUNT(DISTINCT country) AS pocet_zemi,
    MIN(year) AS prvni_rok,
    MAX(year) AS posledni_rok,
    SUM(suicides_no) AS pocet_pripadu,
    ROUND(SUM(suicides_no) * 100000.0 / SUM(population), 1) AS mira_na_100k
FROM suicides;

-- Závěr: Dataset pokrývá 101 zemí v letech 1985–2016 a obsahuje
-- 6 748 420 případů. Celková míra za celé období je 13,1 na 100 000 obyvatel.


-- ---------------------------------------------------------------------
-- 2) MUŽI VS. ŽENY
-- Jaký podíl případů připadá na muže a na ženy a jak se liší míra?
-- ---------------------------------------------------------------------
SELECT
    sex AS pohlavi,
    SUM(suicides_no) AS pocet_pripadu,
    ROUND(SUM(suicides_no) * 100.0 / (SELECT SUM(suicides_no) FROM suicides), 1) AS podil_pct,
    ROUND(SUM(suicides_no) * 100000.0 / SUM(population), 1) AS mira_na_100k
FROM suicides
GROUP BY sex
ORDER BY pocet_pripadu DESC;

-- Závěr: Muži tvoří 76,9 % všech případů (5 188 910), ženy 23,1 %
-- (1 559 510). Míra u mužů (20,7 na 100 000) je zhruba 3,5× vyšší než
-- u žen (5,9).


-- ---------------------------------------------------------------------
-- 3) ZEMĚ S NEJVYŠŠÍM POČTEM PŘÍPADŮ
-- Kterých 10 zemí má za celé období nejvíce případů?
-- ---------------------------------------------------------------------
SELECT
    country AS zeme,
    SUM(suicides_no) AS pocet_pripadu,
    ROUND(SUM(suicides_no) * 100000.0 / SUM(population), 1) AS mira_na_100k
FROM suicides
GROUP BY country
ORDER BY pocet_pripadu DESC
LIMIT 10;

-- Závěr: Nejvíce případů má Rusko (1 209 742), následují USA (1 034 013)
-- a Japonsko (806 902). Absolutní počet ale odráží hlavně velikost
-- populace – např. Brazílie je 8. v počtu případů, ale její míra je jen 4,7.


-- ---------------------------------------------------------------------
-- 4) ZEMĚ S NEJVYŠŠÍ MÍROU
-- Kterých 10 zemí má nejvyšší míru na 100 000 obyvatel?
-- Zahrnuty jsou jen země s daty aspoň za 10 různých let (90 zemí).
-- ---------------------------------------------------------------------
SELECT
    country AS zeme,
    COUNT(DISTINCT year) AS pocet_let,
    ROUND(SUM(suicides_no) * 100000.0 / SUM(population), 1) AS mira_na_100k
FROM suicides
GROUP BY country
HAVING COUNT(DISTINCT year) >= 10
ORDER BY mira_na_100k DESC
LIMIT 10;

-- Závěr: Nejvyšší míru má Litva (41,2 na 100 000), dále Rusko (32,8)
-- a Srí Lanka (30,5). Devět z deseti zemí jsou postkomunistické státy
-- (výjimkou je Srí Lanka). Pořadí se od úkolu 3 výrazně liší, protože míra zohledňuje
-- velikost populace – z top 10 podle počtu zůstaly jen Rusko a Ukrajina.


-- ---------------------------------------------------------------------
-- 5) VĚKOVÉ SKUPINY
-- Jak se míra mění s věkem?
-- ---------------------------------------------------------------------
SELECT
    age_label AS vekova_skupina,
    ROUND(SUM(suicides_no) * 100000.0 / SUM(population), 1) AS mira_na_100k
FROM suicides AS s
INNER JOIN age_groups AS a
    ON s.age = a.age
GROUP BY age_label, sort_order
ORDER BY sort_order;

-- Závěr: Míra s věkem plynule roste – z 0,6 na 100 000 ve skupině
-- 5–14 let na 24,5 ve skupině 75 a více let. Nejohroženější skupinou
-- jsou nejstarší lidé, jejichž míra je téměř dvojnásobná oproti
-- skupině 25–34 let (13,3).


-- ---------------------------------------------------------------------
-- 6) KONTINENTY
-- Který kontinent má nejvyšší míru a kolik zemí ho v datech zastupuje?
-- ---------------------------------------------------------------------
SELECT
    continent AS kontinent,
    COUNT(DISTINCT s.country) AS pocet_zemi,
    ROUND(SUM(suicides_no) * 100000.0 / SUM(population), 1) AS mira_na_100k
FROM suicides AS s
INNER JOIN countries AS c
    ON s.country = c.country
GROUP BY continent
ORDER BY mira_na_100k DESC;

-- Kontrola: součet zemí za všechny kontinenty = 101.
-- Závěr: Nejvyšší míru má Evropa (18,1 na 100 000, 38 zemí), nejnižší
-- Afrika (1,3). Výsledek za Afriku ale není reprezentativní – zastupují
-- ji jen 4 země. Podobně Oceánie (4 země).


-- ---------------------------------------------------------------------
-- 7) VÝVOJ V ČASE A KVALITA DAT
-- A) Jsou data za všechny roky úplná?
-- ---------------------------------------------------------------------
SELECT
    year AS rok,
    COUNT(DISTINCT country) AS pocet_zemi
FROM suicides
GROUP BY year
ORDER BY year;

-- Zjištění: Rok 2016 obsahuje data jen za 16 zemí, ostatní roky za
-- 48–89 zemí. Rok 2016 je neúplný, proto je z analýzy vývoje vyřazen.

-- B) Jak se míra vyvíjela v letech 1985–2015?
SELECT
    year AS rok,
    ROUND(SUM(suicides_no) * 100000.0 / SUM(population), 1) AS mira_na_100k
FROM suicides
WHERE year <> 2016
GROUP BY year
ORDER BY year;

-- Závěr: Míra rostla z 11,5 na 100 000 (1985) na maximum 15,3 v roce 1995.
-- Poté postupně klesala až na 11,5 v roce 2015, tedy na úroveň roku 1985.
-- Pozor: počet zemí v datech se mezi roky mění (48–89), trend je proto
-- třeba brát orientačně.


-- ---------------------------------------------------------------------
-- 8) ČESKO A SOUSEDÉ: 1995 VS. 2014
-- Jak se změnila míra v Česku a okolních zemích mezi lety 1995 a 2014?
-- ---------------------------------------------------------------------
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
FROM mira_zemi
ORDER BY zmena_pct;

-- Závěr: Míra klesla v 5 ze 6 zemí. Nejvýraznější pokles mělo Maďarsko
-- (z 34,6 na 20,5 na 100 000, −40,8 %), následuje Rakousko (−32,6 %).
-- Jedinou zemí s nárůstem je Polsko (z 15,2 na 16,5, +8,6 %).
-- Česko kleslo ze 17,8 na 14,9 (−16,3 %) – jde o nejmenší pokles ze zemí,
-- kde míra klesala. V roce 2014 mělo Česko nižší míru než Maďarsko,
-- Polsko a Rakousko, ale vyšší než Německo (13,2) a Slovensko (10,8).
