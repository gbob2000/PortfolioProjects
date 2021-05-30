--Alex Freberg YouTube tutorial project
SELECT *
FROM CovidPortfolioProject..CovidDeaths
WHERE continent is not null
order by 3,4

-- LOOKING AT TOTAL CASES VS TOTAL DEATHS
-- SHOWS CHANCE OF DYING IF YOU CONTRACT COVID IN YOUR COUNTRY

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM CovidPortfolioProject.. COVIDDEATHS
WHERE location like '%states%'
ORDER BY 1,2

-- TOTAL CASES VS POPULATION

SELECT Location, Date, Population, total_cases, (total_cases/population)*100 as Percent_Infected
FROM CovidPortfolioProject.. COVIDDEATHS
WHERE location like '%states%'
ORDER BY 2

-- LOOKING AT HIGHEST INFECTION RATE COUNTRIES VS POPULATION

SELECT Location, Population, MAX(total_cases) as HighestInfectionCount, Max((total_cases/Population))*100 as Percent_Infected
FROM CovidPortfolioProject.. COVIDDEATHS
--WHERE location like '%states%'
Group By Location, Population
ORDER BY 4 desc

-- LOOKING AT HIGHEST DEATH RATE COUNTRIES PER POPULATION

SELECT Location, population, MAX(cast(total_deaths as int)) as HighestDeathCount, Max((total_deaths/Population))*100 as Percent_Deaths
FROM CovidPortfolioProject.. COVIDDEATHS
WHERE continent is not null
--WHERE location like '%states%'
Group By Location, Population 
ORDER BY 4 desc

--HIGHEST DEATH RATE CONTINENTS 

SELECT location, MAX(cast(total_deaths as int)) as HighestDeathCount
FROM CovidPortfolioProject.. COVIDDEATHS
WHERE continent is null
--WHERE location like '%states%'
Group By location
ORDER BY 2 desc

-- HIGHEST DEATH RATE FOR DRILL DOWN

SELECT continent, MAX(cast(total_deaths as int)) as HighestDeathCount
FROM CovidPortfolioProject.. COVIDDEATHS
WHERE continent is not null
--WHERE location like '%states%' and Continent is not null
Group By continent
ORDER BY 2 desc

-- WORLD DEATHS

SELECT date, SUM(new_cases) as Total_New_Cases, SUM(cast(new_deaths as int)) as Total_New_Deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100  as DeathPercentage
FROM CovidPortfolioProject.. COVIDDEATHS
--WHERE location like '%states%'
WHERE continent is not null
GROUP BY date
ORDER BY 1,2

-- VIEW VACCINATION TABLE
Select * 
from CovidPortfolioProject.. CovidVaccinations

--JOIN DEATHS AND VACCINATION TABLES

SELECT *
FROM CovidPortfolioProject..CovidDeaths dea
JOIN CovidPortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date

-- LOOK AT TOTAL POPULATION VS NEW VACCINATIONS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM CovidPortfolioProject..CovidDeaths dea
JOIN CovidPortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null and vac.new_vaccinations is not null
ORDER BY 2,3

--NEW VAX PER DAY
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION by dea.location
		ORDER BY dea.location, dea.date) as Rolling_Vax_Total
FROM CovidPortfolioProject..CovidDeaths dea
JOIN CovidPortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null and vac.new_vaccinations is not null
ORDER BY 2,3

-- % VAX BY COUNTRY (CTE)

WITH PopVsVax (continent, location, date, population, new_vaccinations, rolling_vax_total)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION by dea.location
		ORDER BY dea.location, dea.date) as Rolling_Vax_Total
FROM CovidPortfolioProject..CovidDeaths dea
JOIN CovidPortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null and vac.new_vaccinations is not null
--ORDER BY 2,3
)
SELECT *, (rolling_vax_total/population)*100 AS Percent_Pop_Vax
FROM PopVsVax

--% VAX BY COUNTRY (Temp table) 
Drop Table if exists #PercentPopVaxed
Create Table #PercentPopVaxed
(
Continent nvarchar(255), 
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
Rolling_vax_total numeric
)
Insert into #PercentPopVaxed
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION by dea.location
		ORDER BY dea.location, dea.date) as Rolling_Vax_Total
FROM CovidPortfolioProject..CovidDeaths dea
JOIN CovidPortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null and vac.new_vaccinations is not null
--ORDER BY 2,3
SELECT *, (rolling_vax_total/population)*100 as RollingPercentVax
FROM #PercentPopVaxed

--CREATE VIEW TO STORE FOR LATER VIZ

Create View PercentPopVaxed as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(cast(vac.new_vaccinations as int)) OVER (PARTITION by dea.location
		ORDER BY dea.location, dea.date) as Rolling_Vax_Total
FROM CovidPortfolioProject..CovidDeaths dea
JOIN CovidPortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null and vac.new_vaccinations is not null
--ORDER BY 2,3

--View data from custom view
SELECT *
FROM PercentPopVaxed
