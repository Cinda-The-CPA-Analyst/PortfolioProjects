select * 
from CovidDeaths
order by 3,4

--select * 
--from CovidVaccinations
--order by 3,4

-- Select Data that we are going to be using
select location, date, total_cases, new_cases, total_deaths, population
from CovidDeaths
order by 1,2 -- (location & date)

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract Covid in your country
select location, date, total_cases, total_deaths, 
	(total_deaths/total_cases)*100 as DeathPercentage
from CovidDeaths
where location like '%state%'
order by 1,2 -- (location & date)

select location, date, total_cases, total_deaths, 
(total_deaths/total_cases)*100 as DeathPercentage
from CovidDeaths
where location like '%china%'
order by 1,2 -- (location & date)

-- Looking at Total Cases vs Populations
-- Showing what percentage of population got Covid: US & China
select location, date, total_cases, population, 
	(total_cases/population)*100 as [%PopulationInfected]
from CovidDeaths
where location like '%state%'or location like '%china'
order by 1,2 -- (location & date)

-- ******************************  Data Exploration *********************************************
select *
from CovidDeaths
where continent is null -- the Location values here are all Continents' Name,
						-- basically, they are values SUM from Group by Continent (Aggregate)
						-- Therefore, here below all SQL will exclude NULL values in the column [continent]


-- Looking at Countries with Highest Infection Rate compared to population

select 
	location, population, 
	Max(total_cases) as HighestInfectionCount, -- Max, the very highest one.
	(Max(total_cases))/population*100 as [%PopulationInfected] -- Max, the highest infected Rate
from CovidDeaths
where continent is not null
Group by location, population
order by [%PopulationInfected] DESC



-- Looking at Countries with Highest Infection Rate compared to population : Top 10
select Top(10)
	location, population, 
	Max(total_cases) as HighestInfectionCount, -- Max, the very highest one.
   (Max(total_cases/population))*100 as [%PopulationInfected] -- Max, the highest infected Rate
from CovidDeaths
where continent is not null
Group by location, population
order by [%PopulationInfected] DESC



-- Looking at Countries: USA vs. China
select 
	location, population, 
	Max(total_cases) as HighestInfectionCount, -- Max, the very highest one.
	(Max(total_cases/population))*100 as [%PopulationInfected] -- Max, the highest infected Rate
from CovidDeaths
where continent is not null
Group by location, population
Having location like '%united state%' or location like '%china%'


-- Showing Countries with Highest Death Count per Population
select continent, location, population,
	Max(convert(int,total_deaths)) as MaxDeathCount 
	-- "Cast/Convert", B4 datatype not right: nvarchar(255)
from CovidDeaths
where continent is not null
Group by continent, location, population
order by MaxDeathCount DESC



-- Showing Countries with Highest Death Count & %DeathCount per Population
select continent, location, population,
	Max(convert(int,total_deaths)) as MaxDeathCount, 
	-- "Cast/Convert", B4 datatype not right: nvarchar(255)
	Max(convert(int,total_deaths)/population)*100 as PercentMaxDeathCount 
from CovidDeaths
where continent is not null
Group by continent, location, population
order by PercentMaxDeathCount DESC


-- Showing Countries with Highest Death Count & %DeathCount per Population: US & China
select continent, location, population,
	Max(convert(int,total_deaths)) as MaxDeathCount, 
	-- "Cast/Convert", B4 datatype not right: nvarchar(255)
	Max(convert(int,total_deaths)/population)*100 as PercentMaxDeathCount 
from CovidDeaths
where continent is not null
Group by continent, location, population
Having location like '%united state%' or location like '%china%'
order by PercentMaxDeathCount DESC


-- Let's Break things down by Location: Showing Continents with the highest Deaths & Rate 
select location,
	Max(convert(int,total_deaths)) as MaxDeathCount, 
	-- "Cast/Convert", B4 datatype not right: nvarchar(255)
	Max(convert(int,total_deaths)/population)*100 as PercentMaxDeathCount -- Calculated column and then Aggregate
from CovidDeaths
where continent is not null
Group by location 
order by PercentMaxDeathCount DESC


-- Let's Break things down by Continent: Showing Continents with the highest Deaths & Rate
select continent, location,
	Max(convert(int,total_deaths)) as MaxDeathCount, 
	-- "Cast/Convert", B4 datatype not right: nvarchar(255)
	Max(convert(int,total_deaths)/population)*100 as PercentMaxDeathCount -- Calculated column and then Aggregate
from CovidDeaths
where continent is null  -- when [continent] is null, location's value is a name of continent, like a group by rollup, or group settings;
Group by continent, location 
order by PercentMaxDeathCount DESC


-- Global Number by date
Select date,
		sum(new_cases) as NewCases,
		sum(convert(int, new_deaths)) as NewDeaths,
		sum(convert(int, new_deaths))/sum(new_cases)*100 as PercentNewDeath
from CovidDeaths
Where continent is not NULL
Group by date
Order by 1,2  DESC

-- Global Number by date, adding a grand total, one extra row to show it.
Select date,
		sum(new_cases) as NewCases,
		sum(convert(int, new_deaths)) as NewDeaths,
		sum(convert(int, new_deaths))/sum(new_cases)*100 as PercentNewDeath,
		Grouping_ID(date) as groupID -- tell us which row is grand total, value is number 1
from CovidDeaths
Where continent is not NULL
Group by rollup(date) -- to get grand total, adding 1 extra line showing grand total.
Order by 1,2  DESC

-- Global Number Grand Total (only 1 row here)
Select --date,
		sum(new_cases) as NewCases,
		sum(convert(int, new_deaths)) as NewDeaths,
		sum(convert(int, new_deaths))/sum(new_cases)*100 as PercentNewDeath
from CovidDeaths
Where continent is not NULL
--Group by date
Order by 1,2  DESC

-- Inner Join Deaths and Vaccinations Tanle together
Select *
from CovidDeaths as D
Join CovidVaccinations as V 
	On D.location = V.location
	and D.date = V.date
Where D.continent is not NULL

-- Looking at Total Population vs. Vaccinations, 
-- Adding Running/Rolling Total on [New_Vaccinations]

Select D.continent, D.location, D.date, D.population, 
		V.total_vaccinations, V.new_vaccinations,
		Sum(Convert(int,V.new_vaccinations)) 
			Over (Partition by D.location Order by D.date) as RTNewVacByLocation, -- Running/Rolling Total Order By Date. adding up to One Location
		Sum(Convert(int,V.new_vaccinations)) 
			Over (Partition by D.location) as TotalNewVacByLocation -- Total by Location
from CovidDeaths as D
Join CovidVaccinations as V 
	On D.location = V.location
	and D.date = V.date
Where D.continent is not NULL and V.new_vaccinations is not NULL
Order by 2,3


--------------------------------- USE CTE 
With PopvsVac (continent, [location], [date], [population], new_vaccinations, RTNewVacByLocation,TotalNewVacByLocation)
As (
Select D.continent, D.location, D.date, D.population, V.new_vaccinations,
		Sum(Convert(int,V.new_vaccinations)) 
			Over (Partition by D.location Order by D.date) as RTNewVacByLocation, 
							-- Running/Rolling Total Order By Date. adding up to One Location
		Sum(Convert(int,V.new_vaccinations)) 
			Over (Partition by D.location) as TotalNewVacByLocation -- Total by Location
from CovidDeaths as D
Join CovidVaccinations as V 
	On D.location = V.location
	and D.date = V.date
Where D.continent is not NULL and V.new_vaccinations is not NULL
-- Order by 2,3
)
select *,  -- Runing with CTE together
RTNewVacByLocation/population*100 As [Percent.RT_NewVac/Pop],
TotalNewVacByLocation/population*100 As [Percent.TotalByLoc/OverPop]
from PopvsVac
Order by 2,3

-------------------------------- Temp Table
Drop table if exists #PercentPopVacc
Go
Create Table #PercentPopVacc
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vacc nvarchar(255),
RTNewVacByLocation numeric,
TotalNewVacByLocation numeric
)
Insert Into #PercentPopVacc 
Select D.continent, D.location, D.date, D.population, V.new_vaccinations,
		Sum(Convert(int,V.new_vaccinations)) 
			Over (Partition by D.location Order by D.date) as RTNewVacByLocation, 
							-- Running/Rolling Total Order By Date. adding up to One Location
		Sum(Convert(int,V.new_vaccinations)) 
			Over (Partition by D.location) as TotalNewVacByLocation -- Total by Location
from CovidDeaths as D
Join CovidVaccinations as V 
	On D.location = V.location
	and D.date = V.date
Where D.continent is not NULL and V.new_vaccinations is not NULL
Order by 2,3

Select *,
	RTNewVacByLocation/TotalNewVacByLocation*100 As PercentRTOverTotalByLoc
from #PercentPopVacc
Order by 2,3

----------- Create a View to store data for later visualizations in Tableau
Drop View if exists [ViewRT&TotalByLoc]
Go
Create View [ViewRT&TotalByLoc] As (
Select D.continent, D.location, D.date, D.population, V.new_vaccinations,
		Sum(Convert(int,V.new_vaccinations)) 
			Over (Partition by D.location Order by D.date) as RTNewVacByLocation, 
							-- Running/Rolling Total Order By Date. adding up to One Location
		Sum(Convert(int,V.new_vaccinations)) 
			Over (Partition by D.location) as TotalNewVacByLocation -- Total by Location
from CovidDeaths as D
Join CovidVaccinations as V 
	On D.location = V.location
	and D.date = V.date
Where D.continent is not NULL and V.new_vaccinations is not NULL
--Order by 2,3
)
Go
select * from [ViewRT&TotalByLoc]
Order by 2,3



