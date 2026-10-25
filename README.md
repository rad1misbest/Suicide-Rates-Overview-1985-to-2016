# Míra sebevražd ve světě 1985–2015 – SQL analýza a Power BI dashboard

Analýza dat WHO o 6,7 milionu případů ve 101 zemích: jak se míra sebevražd liší podle pohlaví, věku, země a kontinentu a jak se vyvíjela v čase.

**Nástroje:** PostgreSQL 17, pgAdmin 4, Power BI Desktop
**Data:** [Kaggle – Suicide Rates Overview 1985 to 2016](https://www.kaggle.com/datasets/russellyates88/suicide-rates-overview-1985-to-2016) (27 820 řádků, 1 řádek = země + rok + pohlaví + věková skupina)



## Hlavní zjištění

1. **Muži tvoří 76,9 % všech případů.** Jejich míra (20,7 na 100 000 obyvatel) je zhruba 3,5× vyšší než u žen (5,9).
2. **Míra s věkem plynule roste** – z 0,6 na 100 000 ve skupině 5–14 let na 24,5 ve skupině 75 a více let.
3. **Nejvyšší míru mají postkomunistické státy.** V top 10 je 9 z nich, na prvním místě Litva (41,2 na 100 000).
4. **Vrchol byl v roce 1995 (15,3 na 100 000)**, od té doby míra klesala až na 11,5 v roce 2015.
5. **Česko a sousedé (1995 vs. 2014):** míra klesla v 5 ze 6 zemí, nejvíc v Maďarsku (−40,8 %). Česko kleslo o 16,3 % – nejméně ze zemí, kde míra klesala. Polsko jako jediné vzrostlo (+8,6 %).

## Metodika

- Míra na 100 000 obyvatel se všude počítá **ze součtů** – `SUM(suicides_no) * 100000.0 / SUM(population)` – ne průměrem sloupce `suicides_per_100k`. Skupiny mají různě velkou populaci a průměr měr by výsledek zkreslil.
- **Rok 2016 je vyřazen** z časových analýz i z dashboardu – obsahuje data jen za 16 zemí (ostatní roky 48–89).
- HDP v CSV je uložené jako text s čárkami (`"2,156,624,900"`) – setup skript ho nahraje do pomocné tabulky, vyčistí a převede na číslo.

## Struktura databáze

| Tabulka | Popis |
|---|---|
| `suicides` | Hlavní data z CSV |
| `countries` | Číselník země → kontinent (dle členění OSN), vytvořen ručně |
| `age_groups` | Číselník věkových skupin – pořadí a český popis, vytvořen ručně |

Propojení: `suicides.country = countries.country`, `suicides.age = age_groups.age`

## Analytické otázky

| # | Otázka | Použité techniky |
|---|---|---|
| 1 | Rozsah dat | `COUNT(DISTINCT)`, `MIN`, `MAX`, `SUM` |
| 2 | Muži vs. ženy | podíl na celku přes poddotaz, míra na 100 000 |
| 3 | Země s nejvyšším počtem případů | `GROUP BY`, `ORDER BY`, `LIMIT` |
| 4 | Země s nejvyšší mírou | `HAVING` s `COUNT(DISTINCT year)` |
| 5 | Věkové skupiny | `INNER JOIN` s číselníkem, řazení přes pořadový sloupec |
| 6 | Kontinenty | `INNER JOIN`, `COUNT(DISTINCT)` |
| 7 | Vývoj v čase a kvalita dat | kontrola úplnosti dat, `WHERE` |
| 8 | Česko a sousedé 1995 vs. 2014 | podmíněná agregace `SUM(CASE …)`, CTE, procentuální změna |

## Dashboard

Interaktivní dashboard v Power BI napojený na PostgreSQL přes view `v_pbi_data`:
- KPI: míra na 100 000 obyvatel a celkový počet případů
- vývoj míry v čase (1985–2015)
- míra podle věku a pohlaví
- top 10 zemí podle míry
- filtr podle kontinentu

Dashboard pracuje s daty bez roku 2016, proto se některé hodnoty mírně liší od SQL analýzy za celé období (např. Litva 41,5 vs. 41,2).

## Soubory

```
sql/01_setup.sql           – vytvoření tabulek a nahrání dat
sql/02_analyza.sql         – 8 analytických dotazů se závěry
sql/03_powerbi_views.sql   – view pro Power BI
dashboard/Dashboard.pbix   – Power BI dashboard
images/dashboard.png       – náhled dashboardu
```

## Jak spustit

1. Stáhni CSV z Kaggle (odkaz výše).
2. V `sql/01_setup.sql` uprav cestu k CSV v příkazu `\copy`.
3. V pgAdminu vytvoř databázi, otevři **PSQL Tool** a spusť `\i 'cesta/01_setup.sql'`.
4. V Query Tool spusť `02_analyza.sql` a `03_powerbi_views.sql`.
5. Otevři `Dashboard.pbix` a v nastavení zdroje dat uprav připojení k databázi.

## Omezení

- Počet zemí se mezi roky mění, celosvětový trend je proto částečně ovlivněn tím, které země v daném roce data poskytly.
- V datech chybí např. Čína a Indie, Afriku zastupují jen 4 země.
- Sloupec `hdi_for_year` je ze 70 % prázdný, proto se nepoužívá.
- Data ukazují souvislosti, ne příčiny.
