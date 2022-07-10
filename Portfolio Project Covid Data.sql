
--Covid 19 Data Exploration 

SELECT *
FROM Project..CovidVaccinations

--Selecting data that we are going to be using
SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM Project..CovidDeaths
ORDER BY Location, date

--Looking at Total Cases vs Total Deaths
--Likehood of dying if you catch covid in your country which in this case is United States
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM Project..CovidDeaths
WHERE Location like '%States'
ORDER BY Location, date

--Looking at Total Cases vs Population
--Shows what percentage of population got Covid 
SELECT Location, date, Population, total_cases, (total_cases/Population)*100 AS InfectedPopulationPercentage
FROM Project..CovidDeaths
WHERE Location like '%States'
ORDER BY Location, date

--Looking at Countries with Highest Infection Rate compared to Population
SELECT Location, Population, MAX(total_cases) AS HighestInfectionCount,  
MAX((total_cases/Population))*100 AS PercentPopulationInfection
FROM Project..CovidDeaths
GROUP BY Location, Population
ORDER BY PercentPopulationInfection DESC

--Showing Countries with Highest Death Count Per Population
--Converting total deaths data type from nvar(character) to int
SELECT Location, MAX(cast(total_deaths as int)) AS TotalDeathCount  
FROM Project..CovidDeaths
WHERE continent is NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC

--Lets Break this down by continent now

--Showing continents with the highest death count per population
SELECT continent, MAX(cast(total_deaths as int)) AS TotalDeathCount  
FROM Project..CovidDeaths
WHERE continent is not NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

--Global Numbers
--Total number of new cases, deaths and their death percentage for that particular date 
SELECT date, SUM(new_cases) AS Total_Cases, SUM(cast(new_deaths as int)) AS Total_Deaths,
(SUM(cast(new_deaths as int))/SUM(new_cases))*100 AS DeathPercentage
FROM Project..CovidDeaths
WHERE continent is not NULL
GROUP BY date
ORDER BY date, Total_Cases

--Total number of new cases, deaths and their death percentage for the whole world
SELECT SUM(new_cases) AS Total_Cases, SUM(cast(new_deaths as int)) AS Total_Deaths,
(SUM(cast(new_deaths as int))/SUM(new_cases))*100 AS DeathPercentage
FROM Project..CovidDeaths
WHERE continent is not NULL
ORDER BY Total_Cases, Total_Deaths

--Looking at Total Population vs Vaccinations
--We are using the PARTITION BY to set up a rolling count for the new vaccinations.
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVacinated
FROM Project..CovidDeaths AS dea
JOIN Project..CovidVaccinations AS vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

--Because we can't use the RollingCount column which we just created in our previous query to perform query on that column.
--Therefore, we will create a CTE/Temp table for it.
--CTE
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVacinated)
AS 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVacinated
FROM Project..CovidDeaths AS dea
JOIN Project..CovidVaccinations AS vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVacinated/Population)*100 AS RollingCountPercentage
FROM PopvsVac

--Using Temp Table for the same query
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
new_vaccinations numeric,
RollingPeopleVacinated numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVacinated
FROM Project..CovidDeaths AS dea
JOIN Project..CovidVaccinations AS vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT *, (RollingPeopleVacinated/Population)*100 AS RollingCountPercentage
FROM #PercentPopulationVaccinated


--Create a View to store data for later visualization
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVacinated
FROM Project..CovidDeaths AS dea
JOIN Project..CovidVaccinations AS vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT *
FROM PercentPopulationVaccinated

--Creating another View
CREATE VIEW GlobalStats AS
SELECT continent, MAX(cast(total_deaths as int)) AS TotalDeathCount  
FROM Project..CovidDeaths
WHERE continent is not NULL
GROUP BY continent
--ORDER BY TotalDeathCount DESC

SELECT * 
FROM GlobalStats

/*
Queries used for Tableau Project
*/
-- 1) 
SELECT SUM(new_cases) AS total_cases, SUM(cast(new_deaths as int)) AS total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 AS DeathPercentage
FROM Project..CovidDeaths
--WHERE location LIKE '%states%'
WHERE continent is not null 
--GROUP BY date
ORDER BY 1,2

-- 2) 
-- We take these out as they are not inluded in the above queries and want to stay consistent
-- European Union is part of Europe, income classes are being excluded as we are just working on continent. 
SELECT location, SUM(cast(new_deaths as int)) AS TotalDeathCount
FROM Project..CovidDeaths
--WHERE location LIKE '%states%'
WHERE continent is null 
AND LOCATION NOT IN ('World', 'European Union', 'International', 'Upper middle income', 'High income', 'Lower middle income', 'Low income')
GROUP BY location
ORDER BY TotalDeathCount DESC

-- 3)
SELECT Location, Population, MAX(total_cases) AS HighestInfectionCount,  Max((total_cases/population))*100 AS PercentPopulationInfected
FROM Project..CovidDeaths
--WHERE location LIKE '%states%'
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC

-- 4)
SELECT Location, Population, date, MAX(total_cases) AS HighestInfectionCount, Max((total_cases/population))*100 AS PercentPopulationInfected
FROM Project..CovidDeaths
--WHERE location LIKE '%states%'
GROUP BY Location, Population, date
ORDER BY PercentPopulationInfected DESC
