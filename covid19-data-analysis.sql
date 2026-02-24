
USE PortfolioProject
select * from PortfolioProject..CovidDeathscsv$
order by 3,4;

SELECT *
FROM CovidDeathscsv$;


SELECT *
FROM dbo.CovidDeathscsv$;

SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'CovidVaccination$';


select country,
    date,
    total_cases,
    new_cases,
    population,
    total_deaths  from PortfolioProject..CovidDeathscsv$ order by 1,2

    --looking at the cases vs total deaths
    select country,date,total_cases,total_deaths,ROUND(total_deaths * 100.0/NULLIF(total_cases,0),2) as death_percentage 
    from PortfolioProject..CovidDeathscsv$ where country like '%state%' order by 2 desc;




    --looking at the total cases vs population
    select country,date, population,total_cases,round((total_cases/population),3)*100 as death_percentage 
    from PortfolioProject..CovidDeathscsv$ where country like '%ladesh%' order by 1,2;


    -- looking at countries with highest infection rate compare to population
    select country,  population, max(total_cases) as highestinfection
    from CovidDeathscsv$ where continent is not null group by country ,  population order by  highestinfection desc;


    --professional
    SELECT
    country,
    MAX(population) as population,
    MAX(total_cases) as highestinfection,
    MAX(total_cases)*100.0 / NULLIF(MAX(population),0) AS percentage_population
FROM PortfolioProject..CovidDeathscsv$
WHERE continent IS NOT NULL
GROUP BY country , population
ORDER BY percentage_population DESC;



--SHOWING COUNTRY WITH HIGHEST DEATH

    SELECT
    country,
    MAX(total_deaths) as total_deathcount
FROM PortfolioProject..CovidDeathscsv$
WHERE continent IS NOT NULL
  AND population IS NOT NULL
GROUP BY country 
ORDER BY  total_deathcount DESC;





-- lets break things down by continent
  SELECT
 continent,
    MAX(total_deaths) as total_deathcount
FROM PortfolioProject..CovidDeathscsv$
WHERE continent IS not NULL
  AND population IS NOT NULL
GROUP BY continent
ORDER BY  total_deathcount DESC;



--continent with highest death count

    SELECT
   continent,
    MAX(total_deaths) as total_deathcount
FROM PortfolioProject..CovidDeathscsv$
WHERE continent IS NOT NULL
  AND population IS NOT NULL
GROUP BY continent 
ORDER BY  total_deathcount DESC;



--GLOBAL NUMBERS


SELECT 
    --date,
    SUM(new_cases) AS total_cases,
    SUM(new_deaths) AS total_deaths,
    SUM(new_deaths) / NULLIF(SUM(new_cases),0)* 100.0  AS death_percentage
FROM PortfolioProject..CovidDeathscsv$
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2;



--looking at total population vs vaccination
SELECT
  d.continent, d.country, d.date, d.population,
  v.new_vaccinations,
  SUM(TRY_CONVERT(float, v.new_vaccinations)) 
    OVER (PARTITION BY d.country ORDER BY d.date) AS rolling_vaccinations
FROM PortfolioProject..CovidDeathscsv$ d
JOIN PortfolioProject..CovidVaccination$ v
  ON d.country = v.country AND d.date = v.date
WHERE d.continent IS NOT NULL
ORDER BY d.country, d.date;


--use cte
WITH PopvsVac AS
(
  SELECT
    d.continent,
    d.country AS location,
    d.date,
    TRY_CONVERT(float, REPLACE(REPLACE(d.population, ',', ''), ' ', '')) AS population,
    TRY_CONVERT(float, REPLACE(REPLACE(v.new_vaccinations, ',', ''), ' ', '')) AS new_vaccinations,
    SUM(
      COALESCE(TRY_CONVERT(float, REPLACE(REPLACE(v.new_vaccinations, ',', ''), ' ', '')), 0)
    ) OVER (PARTITION BY d.country ORDER BY d.date) AS rolling_vaccinations
  FROM PortfolioProject..CovidDeathscsv$ d
  JOIN PortfolioProject..CovidVaccination$ v
    ON d.country = v.country AND d.date = v.date
  WHERE d.continent IS NOT NULL
)
SELECT *,
       (rolling_vaccinations * 100.0) / NULLIF(population, 0) AS perpopulation
FROM PopvsVac;





DROP TABLE IF EXISTS #PercentPopulationVaccinated;

CREATE TABLE #PercentPopulationVaccinated
(
  continent nvarchar(255),
  country nvarchar(255),
  [date] datetime,
  population float,
  new_vaccination float,
  RollingPeopleVaccinated float
);

INSERT INTO #PercentPopulationVaccinated
    (continent, country, [date], population, new_vaccination, RollingPeopleVaccinated)
SELECT
    d.continent,
    d.country,
    d.date,
    TRY_CONVERT(float, REPLACE(REPLACE(d.population, ',', ''), ' ', '')) AS population,
    TRY_CONVERT(float, REPLACE(REPLACE(v.new_vaccinations, ',', ''), ' ', '')) AS new_vaccination,
    SUM(
        COALESCE(TRY_CONVERT(float, REPLACE(REPLACE(v.new_vaccinations, ',', ''), ' ', '')), 0)
    ) OVER (PARTITION BY d.country ORDER BY d.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeathscsv$ d
JOIN PortfolioProject..CovidVaccination$ v
  ON d.country = v.country AND d.date = v.date
WHERE d.continent IS NOT NULL;

SELECT *,
       (RollingPeopleVaccinated * 100.0) / NULLIF(population, 0) AS perpopulation
FROM #PercentPopulationVaccinated
ORDER BY country, [date];



--Creating view for storing data for late visualization





CREATE VIEW dbo.PercentPopulationVaccinated AS
SELECT
    d.continent,
    d.country,
    d.date,
    TRY_CONVERT(float, REPLACE(REPLACE(d.population, ',', ''), ' ', '')) AS population,
    TRY_CONVERT(float, REPLACE(REPLACE(v.new_vaccinations, ',', ''), ' ', '')) AS new_vaccination,
    SUM(
        COALESCE(
            TRY_CONVERT(float, REPLACE(REPLACE(v.new_vaccinations, ',', ''), ' ', '')), 
            0
        )
    ) OVER (PARTITION BY d.country ORDER BY d.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeathscsv$ d
JOIN PortfolioProject..CovidVaccination$ v
    ON d.country = v.country
   AND d.date = v.date
WHERE d.continent IS NOT NULL;



