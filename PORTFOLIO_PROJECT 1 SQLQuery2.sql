select *
from portfolio_project..CovidDeaths$ 
where continent is not null
order by 3, 4

-- to select the data we are going to be using 

select location, date, total_cases , new_cases, total_deaths , population 
from portfolio_project..CovidDeaths$ 
where continent is not null
order by 1, 2

--  1. total cases vs total deaths. percentage of people who reported that they were infected but died. 
-- shows the likelihood of dying if an individual contracts COVID in a location

select location, date, total_cases , total_deaths, (total_deaths /total_cases )*100 as DeathPercentage
from portfolio_project..CovidDeaths$ 
where location like '%states%' -- to view results of location(s) that has 'states' in it.
and continent is not null
order by 1, 2


-- 2. total cases vs population
-- shows the percentage of the population that has gotten COVID 

select location, date, total_cases , population , (total_cases/population)*100 as PercentInfected
from portfolio_project..CovidDeaths$ 
where location like '%states%' -- to view results of location(s) that has 'states' in it.
		and continent is not null
order by 1, 2

-- 3. what countries have the highest infection rate compared to the population?

select location, population , max(total_cases) as HighestInfectionCount, max((total_cases/population))*100 as PercentInfected
from portfolio_project..CovidDeaths$ 
where continent is not null
group by location, population 
order by PercentInfected desc

-- 4. showing countries with highest death count per population 
-- to get an accurate result for this query the data type of total_deaths has to be changed from nvarchar to an integer.

select location , max(cast(total_deaths as int)) as TotalDeathCount
from portfolio_project..CovidDeaths$ 
where continent is not null
group by location
order by TotalDeathCount desc

-- 5. To break things down by continent

select location , max(cast(total_deaths as int)) as TotalDeathCount
from portfolio_project..CovidDeaths$ 
where continent is null
group by location 
order by TotalDeathCount desc

select continent , max(cast(total_deaths as int)) as TotalDeathCount
from portfolio_project..CovidDeaths$ 
where continent is not null
group by continent 
order by TotalDeathCount desc

-- 6. GLOBAL FIGURES

select date, sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, Sum(cast(new_deaths as int))/sum(new_cases)*100 as DeathPercentage
from portfolio_project..CovidDeaths$ 
where continent is not null
group by date 
order by 1, 2


-- 7. merging covid deaths with covid vaccination 

select *
from PORTFOLIO_PROJECT ..CovidDeaths$ dea
join PORTFOLIO_PROJECT ..CovidVaccinations$ vac
	on dea.location =vac.location 
	and dea.date = vac.date

-- 8. looking at total population vs total vaccination 

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
from PORTFOLIO_PROJECT ..CovidDeaths$ dea
join PORTFOLIO_PROJECT ..CovidVaccinations$ vac
	on dea.location =vac.location 
	and dea.date = vac.date
where dea.continent is not null
order by 2, 3

-- 9. to partition the sums of vaccinated poeple by location 
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	sum(convert (int, vac.new_vaccinations)) OVER (partition by dea.location order by dea.location, dea.date)
	as RollingPeopleVaccinated
from PORTFOLIO_PROJECT ..CovidDeaths$ dea
join PORTFOLIO_PROJECT ..CovidVaccinations$ vac
	on dea.location =vac.location 
	and dea.date = vac.date
where dea.continent is not null
order by 2, 3

-- 10. (total number of vaccinated people/population) rate
-- USE CTE
with popvsvac (continent, location, date, population,new_vaccinations, rollingpeoplevaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	sum(convert (int, vac.new_vaccinations)) OVER (partition by dea.location order by dea.location, dea.date)
	as RollingPeopleVaccinated
from PORTFOLIO_PROJECT ..CovidDeaths$ dea
join PORTFOLIO_PROJECT ..CovidVaccinations$ vac
	on dea.location =vac.location 
	and dea.date = vac.date
where dea.continent is not null
)
select*, (rollingpeoplevaccinated /population )*100
from popvsvac 
 
 -- 11. using TEMP TABLE

 drop table if exists #percentpopulationvaccinated -- incase any alterations have to be made to the table
 create table #PercentpopulationVaccinated
 (
 continent nvarchar (255),
 location nvarchar (255),
 date datetime, 
 population numeric ,
 new_vaccinations numeric,
 rollingpeoplevaccinated numeric
 )

 insert into #PercentpopulationVaccinated 
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	sum(convert (int, vac.new_vaccinations)) OVER (partition by dea.location order by dea.location, dea.date)
	as RollingPeopleVaccinated
from PORTFOLIO_PROJECT ..CovidDeaths$ dea
join PORTFOLIO_PROJECT ..CovidVaccinations$ vac
	on dea.location =vac.location 
	and dea.date = vac.date
-- where dea.continent is not null

select*, (rollingpeoplevaccinated /population )*100
from #percentpopulationvaccinated  
 

 -- 12. creating view to store data later for visualizations

 create view percentagepopulationvaccinated as
 select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	sum(convert (int, vac.new_vaccinations)) OVER (partition by dea.location order by dea.location, dea.date)
	as RollingPeopleVaccinated
from PORTFOLIO_PROJECT ..CovidDeaths$ dea
join PORTFOLIO_PROJECT ..CovidVaccinations$ vac
	on dea.location =vac.location 
	and dea.date = vac.date
where dea.continent is not null
-- order by 2, 3


