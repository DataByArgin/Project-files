-- Death percentage in Armenia
select location_, date_, total_cases, total_deaths, cast((total_deaths::real/total_cases)*100 as numeric(4,2)) || '%' as DeathPercentage
from CovidDeaths
where location_ = 'Armenia'
order by 2 desc

-- Percentage of population infected in Armenia
select location_, date_, population, total_cases, cast((total_cases::real/population)*100 as numeric(4,2)) || '%' as Population_Infected
from CovidDeaths
where location_ = 'Armenia'
order by 2 desc
-- Highest infection and Percentage of population infected
select location_, population, MAX(total_cases) as HighestInfectionCount,
	cast(MAX((total_cases::real/population))*100 as numeric(4,2)) || '%' as Percent_Population_Infected
from CovidDeaths
where total_cases is not null
group by location_, population
order by 2

-- Highest death count per population
select location_, max(total_deaths) as Total_Death_Count
from CovidDeaths
where continent is not null
group by location_
order by Total_Death_Count desc

-- Highest death count per population (continent)
select continent, max(total_deaths) as Total_Death_Count
from CovidDeaths
where continent is not null
group by continent
order by Total_Death_Count desc

-- Global numbers
select sum(new_cases) as Total_cases,
	   sum(new_deaths) as Total_deaths,
	   (sum(new_deaths::real)/sum(new_cases))*100 as Death_Percentage
from CovidDeaths
where continent is not null

select *
from CovidDeaths dea
join CovidVaccinations vac
	on dea.location_ = vac.location_
	and dea.date_ = vac.date_
	
-- Total population vs vaccinations
select dea.continent, dea.location_, dea.date_, dea.population, vac.new_vaccinations,
	sum(vac.new_vaccinations) over (partition by dea.location_) as Total_people_vaccinated
from CovidDeaths dea
join CovidVaccinations vac
	on dea.location_ = vac.location_
	and dea.date_ = vac.date_
where dea.continent is not null
order by Total_people_vaccinated

-- Use CTE
with PopvsVac (continent, location_, date_, population, new_vaccinations, Total_people_vaccinated)
as
(
select dea.continent, dea.location_, dea.date_, dea.population, vac.new_vaccinations,
	sum(vac.new_vaccinations) over (partition by dea.location_) as Total_people_vaccinated
from CovidDeaths dea
join CovidVaccinations vac
	on dea.location_ = vac.location_
	and dea.date_ = vac.date_
where dea.continent is not null
--order by Total_people_vaccinated
)
select *, (Total_people_vaccinated/population)*100 as 
from PopvsVac

-- Temp table
drop table if exists PercentVaccinated;
create table PercentVaccinated
(
	continent varchar(225),
	location_ varchar(225),
	date_ date,
	population numeric,
	new_vaccinations numeric,
	Total_people_vaccinated numeric
);
insert into PercentVaccinated
select dea.continent, dea.location_, dea.date_, dea.population, vac.new_vaccinations,
	sum(vac.new_vaccinations) over (partition by dea.location_) as Total_people_vaccinated
from CovidDeaths dea
join CovidVaccinations vac
	on dea.location_ = vac.location_
	and dea.date_ = vac.date_;
	
select *, (Total_people_vaccinated/population)*100
from PercentVaccinated

-- Creating view to store data for later visualization

create view PercentVaccinatedView as
select dea.continent, dea.location_, dea.date_, dea.population, vac.new_vaccinations,
	sum(vac.new_vaccinations) over (partition by dea.location_) as Total_people_vaccinated
from CovidDeaths dea
join CovidVaccinations vac
	on dea.location_ = vac.location_
	and dea.date_ = vac.date_
where dea.continent is not null