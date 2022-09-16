select * 
from PortfolioProjectCovid..CovidDeaths
order by 3,4

-- Select data that we are going to be using

select location, date, total_cases, new_cases, total_deaths, population
from PortfolioProjectCovid..CovidDeaths
order by 1,2

-- Compare the total cases with the total deaths : what percentage of the population who got covid actually died  everyday ?

	--world

Select location, date, total_cases, total_deaths, population, (total_deaths/total_cases)*100 as Death_rate
from PortfolioProjectCovid..CovidDeaths
order by 1,2

	--in Canada

Select location, date, total_cases, total_deaths, population, (total_deaths/total_cases)*100 as Death_rate
from PortfolioProjectCovid..CovidDeaths
where location like '%Canada%'
order by 1,2


-- Daily infection rate 

Select location, date, total_cases, population, (total_cases/population)*100 as Infection_rate
from PortfolioProjectCovid..CovidDeaths
order by 1,2

-- Which country has the highest infection rate

Select location, MAX(total_cases) as InfectionCount, population, MAX((total_cases/population))*100 as Infection_rate
from PortfolioProjectCovid..CovidDeaths
group by location, population
order by Infection_rate desc

-- Countries with the highest death count

Select location, MAX(cast(total_deaths as int)) as DeathCount
from PortfolioProjectCovid..CovidDeaths
where continent is not null
group by location, population
order by DeathCount desc

-- Death count by continent

Select location, MAX(cast(total_deaths as int)) as DeathCount
from PortfolioProjectCovid..CovidDeaths
where continent is null
group by location
order by DeathCount desc

-- Getting global numbers : total cases, total deaths, total death rate

Select SUM(new_cases) as TotalCases, SUM(cast(new_deaths as int)) as TotalDeaths, 
SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathRate
from PortfolioProjectCovid..CovidDeaths
where continent is not null
order by 1,2

-- Add vaccination data

Select *
from PortfolioProjectCovid..CovidDeaths dea
Join PortfolioProjectCovid..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date

-- Vaccination count

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as CumulatedVaccinations
from PortfolioProjectCovid..CovidDeaths dea
Join PortfolioProjectCovid..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3


-- Cumulated Vaccination rate

With VaccinationRate (Continent, Location, Date, Population, New_vaccinations, CumulatedVaccinations)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.location order by dea.location, dea.date)
as CumulatedVaccinations
from PortfolioProjectCovid..CovidDeaths dea
Join PortfolioProjectCovid..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
)

Select * , (CumulatedVaccinations/Population)*100 as CumulatedVaccinationRate
from VaccinationRate

-- Find out the infection rate per country using the cumulated vaccination rates

With Vaccination_Rate (Continent, Location, Date, Population, New_vaccinations, CumulatedVaccinations)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.location order by dea.location, dea.date)
as CumulatedVaccinations
from PortfolioProjectCovid..CovidDeaths dea
Join PortfolioProjectCovid..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
)

Select continent, location , MAX(CumulatedVaccinations/Population)*100 as TotalVaccinationRate
from Vaccination_Rate
where continent like '%europe%'
group by location, continent
order by TotalVaccinationRate desc


-- TEMP TABLE

DROP TABLE IF EXISTS #PercentPopulationVaccinated
Create table #PercentPopulationVaccinated
(Continent nvarchar (255),
Location nvarchar (255),
Date datetime,
Population numeric,
New_vaccinations numeric,
CumulatedVaccinations numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.location order by dea.location, dea.date)
as CumulatedVaccinations
from PortfolioProjectCovid..CovidDeaths dea
Join PortfolioProjectCovid..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

Select * , (CumulatedVaccinations/Population)*100 as CumulatedVaccinationRate
from #PercentPopulationVaccinated

-- Creating view to store data for later visualization

Create view PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.location order by dea.location, dea.date)
as CumulatedVaccinations
from PortfolioProjectCovid..CovidDeaths dea
Join PortfolioProjectCovid..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

Create view InfectionRate as
Select location, MAX(total_cases) as InfectionCount, population, MAX((total_cases/population))*100 as Infection_rate
from PortfolioProjectCovid..CovidDeaths
group by location, population

Create view DeathCountWorld as
Select location, MAX(cast(total_deaths as int)) as DeathCount
from PortfolioProjectCovid..CovidDeaths
where continent is null
group by location