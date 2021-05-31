/* 
COVID 19 data exploration:
Skills used: Joins, CTE's, Temp tables, Windows functions, Aggregate functions, Creating views, Converting data types
*/

-- 1. Data to be working with

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY 1, 2

-- 2. Total cases vs total deaths. Chances of dying due to COVID.

SELECT location, date, total_cases, total_deaths, ROUND((total_deaths/total_cases)*100, 2) AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2 

	-- 2a. Creating View

	CREATE VIEW LikelihoodDeath AS
	SELECT location, date, total_cases, total_deaths, ROUND((total_deaths/total_cases)*100, 2) AS DeathPercentage
	FROM CovidDeaths
	WHERE continent IS NOT NULL

-- 3. Total cases vs total population. Percentage of population with COVID.

SELECT location, date, population, total_cases, (total_cases/population)*100 AS InfectionPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2 

	-- 3a. Creating View

	CREATE VIEW LikelihoodInfection AS
	SELECT location, date, population, total_cases, (total_cases/population)*100 AS InfectionPercentage
	FROM CovidDeaths
	WHERE continent IS NOT NULL


-- 4. Countries with highest infection rate compared to population.

SELECT location, population, MAX(total_cases) AS MaxCases, MAX((total_cases/population))*100 AS InfectionPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 4 DESC

	-- 4a. Creating view

	CREATE VIEW CountryMaxCases AS
	SELECT location, population, MAX(total_cases) AS MaxCases, MAX((total_cases/population))*100 AS InfectionPercentage
	FROM CovidDeaths
	WHERE continent IS NOT NULL
	GROUP BY location, population

-- 5. Countries with highest deaths compared to population

SELECT location, population, MAX(CAST(total_deaths AS int)) AS MaxDeathsCount -- Cast because total_deaths is nVarchar
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 3 DESC

	-- 5a. Creating View

	CREATE VIEW CountryMaxDeath AS
	SELECT location, population, MAX(CAST(total_deaths AS int)) AS MaxDeathsCount -- Cast because total_deaths is nVarchar
	FROM CovidDeaths
	WHERE continent IS NOT NULL
	GROUP BY location, population

-- 6. Highest death count per Continent

SELECT location, MAX(CAST(total_deaths AS int)) AS DeathsCount
FROM CovidDeaths
WHERE continent IS NULL AND location NOT IN ('World', 'International', 'European Union')
GROUP BY location
ORDER BY 2 DESC

	-- 6a. Creating Views for visualizations

	CREATE VIEW DeathInContinents AS
	SELECT location, MAX(CAST(total_deaths AS int)) AS DeathsCount
	FROM CovidDeaths
	WHERE continent IS NULL
	GROUP BY location

	-- 6b. Altering the above view to filter in more specific continents

	ALTER VIEW DeathInContinents AS
	SELECT location, MAX(CAST(total_deaths AS int)) AS DeathsCount
	FROM CovidDeaths
	WHERE continent IS NULL AND location NOT IN ('World', 'International', 'European Union')
	GROUP BY location

-- 7. Global infection and deaths numbers per day

SELECT date, SUM(new_cases) AS Total_cases, SUM(CAST(new_deaths AS int)) AS Total_deaths,
SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS Death_Percentage
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, 2

-- 8. Total global infection and deaths numbers

SELECT SUM(new_cases) AS Total_cases, SUM(CAST(new_deaths AS int)) AS Total_deaths,
SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS Death_Percentage
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2

	-- 8a. Creating View

	CREATE VIEW GlobalStatistics AS
	SELECT SUM(new_cases) AS Total_cases, SUM(CAST(new_deaths AS int)) AS Total_deaths,
	SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS Death_Percentage
	FROM CovidDeaths
	WHERE continent IS NOT NULL

-- 9. Total Population vs Vaccinations

SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations
FROM CovidDeaths AS d
JOIN CovidVaccinations AS v
ON d.location = v.location AND d.date= v.date
WHERE d.continent IS NOT NULL
ORDER BY 2,3

-- 10. Adding daily increment of vaccines to the above query 

SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
SUM(CONVERT(int, V.new_vaccinations)) OVER(PARTITION BY d.location ORDER BY d.date, d.location) AS
RollingPeopleVaccinated
FROM CovidDeaths AS d
JOIN CovidVaccinations AS v
ON d.location = v.location AND d.date= v.date
WHERE d.continent IS NOT NULL
ORDER BY 2,3

-- 11. Amount of the population vaccinated
-- 11.1. Using CTE to perform calculation on Partition by in previous query

WITH PopvsVac (Continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
SUM(CONVERT(int, V.new_vaccinations)) OVER(PARTITION BY d.location ORDER BY d.date, d.location) AS
RollingPeopleVaccinated
FROM CovidDeaths AS d
JOIN CovidVaccinations AS v
ON d.location = v.location AND d.date= v.date
WHERE d.continent IS NOT NULL
)
SELECT *, RollingPeopleVaccinated/population*100 AS PercerntagePopleVac
FROM PopvsVac
ORDER BY 2,3

-- 11.2. Using Temp Table to perform calculation on Partition by in previous query

DROP TABLE IF EXISTS NPopVaccinated
CREATE TABLE NPopVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)
INSERT INTO NPopVaccinated
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations,
SUM(CONVERT(int, V.new_vaccinations)) OVER(PARTITION BY d.location ORDER BY d.date, d.location) AS
RollingPeopleVaccinated
FROM CovidDeaths AS d
JOIN CovidVaccinations AS v
ON d.location = v.location AND d.date= v.date
WHERE d.continent IS NOT NULL

SELECT*, (RollingPeopleVaccinated)/Population*100 AS PercerntagePopleVac
from NPopVaccinated
ORDER BY 2,3





