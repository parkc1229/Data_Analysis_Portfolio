--select *
--from CovidAnalysis..CovidDeaths
--where continent is not null
--order by 3, 4

--select *
--from CovidAnalysis..CovidVaccinations
--order by 3, 4


-- Select the data that we are going to be using
select location, date, total_cases, new_cases, total_deaths, population
from CovidAnalysis..CovidDeaths
order by 1, 2


alter table dbo.CovidDeaths alter column total_deaths float
alter table dbo.CovidDeaths alter column total_cases float
alter table dbo.CovidDeaths alter column population float
alter table dbo.CovidDeaths alter column date date
alter table dbo.CovidDeaths alter column new_deaths float
alter table dbo.CovidDeaths alter column new_cases float



-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract COVID in your country
select location, date, total_cases, total_deaths, (total_deaths/NULLIF(total_cases, 0))*100 as DeathPercentage
from CovidAnalysis..CovidDeaths
-- where location like '%states%' // this shows where location "contains" 'states'
order by 1, 2


-- Looking at Total Cases vs Population
-- Shows what percentage of population got COVID
select location, date, population, total_cases, (total_cases/NULLIF(population, 0))*100 as PercentPopulationInfected
from CovidAnalysis..CovidDeaths
order by 1, 2


-- Looking at Countries with Highest Infection Rate compared to Population
select location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/NULLIF(population, 0)))*100 as PercentPopulationInfected
from CovidAnalysis..CovidDeaths
group by location, population
order by PercentPopulationInfected desc


-- Showing Countries with Highest Death Count per Population
select location, MAX(total_deaths) as TotalDeathCount
from CovidAnalysis..CovidDeaths
where continent != ''
group by location
order by TotalDeathCount desc



-- Let's break things down by Continent
-- Showing continents with the highest death counts
select continent, MAX(total_deaths) as TotalDeathCount
from CovidAnalysis..CovidDeaths
where continent != ''
group by continent
order by TotalDeathCount desc



-- Global Numbers

select date, SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(new_deaths)/NULLIF(SUM(new_cases), 0)*100 as DeathPercentage
from CovidAnalysis..CovidDeaths
-- where location like '%states%'
where continent != ''
group by date
order by 1, 2



-- Looking at Total Population vs Vaccinations
-- Incorporates a rolling count as vaccinations in each country goes up
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(float, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, 
dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population) * 100  // can't do this because you just created RollingPeopleVaccinated
from CovidAnalysis..CovidDeaths dea
join CovidAnalysis..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent != ''
order by 1, 2, 3



-- USE CTE
-- Essentially using the queried table to make a new table PopvsVac where you can then use RollingPeopleVaccinated
With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(float, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, 
dea.date) as RollingPeopleVaccinated
from CovidAnalysis..CovidDeaths dea
join CovidAnalysis..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent != ''
--order by 1, 2, 3
)
Select *, (RollingPeopleVaccinated/NULLIF(Population, 0))*100
from PopvsVac



-- USE TEMP TABLE
-- Another way of doing what we did above
-- creates a table with RollingPeopleVaccinated for us to use and then drops it
DROP TABLE if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(float, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, 
dea.date) as RollingPeopleVaccinated
from CovidAnalysis..CovidDeaths dea
join CovidAnalysis..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent != ''
--order by 1, 2, 3

Select *, (RollingPeopleVaccinated/NULLIF(Population, 0))*100
from #PercentPopulationVaccinated



-- Creating View to store dat for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(float, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, 
dea.date) as RollingPeopleVaccinated
from CovidAnalysis..CovidDeaths dea
join CovidAnalysis..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent != ''
--order by 1, 2, 3



Select * 
From PercentPopulationVaccinated