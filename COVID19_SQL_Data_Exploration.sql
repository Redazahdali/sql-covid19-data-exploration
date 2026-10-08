/*
SQL DATA EXPLORATION — COVID-19
SQL Server / T-SQL

Les requêtes SQL originales sont conservées.
Des explications et séparateurs ont été ajoutés pour documenter le projet.
*/

SELECT * from [PortfolioProject].[dbo].[CovidDeaths]
where continent is not null

--SELECT * from [PortfolioProject].[dbo].[CovidVaccinations]

SELECT location, date, total_cases, new_cases , total_deaths, population from [PortfolioProject].[dbo].[CovidDeaths]
order by 1,2

/*
***
ÉTAPE 1 — Cas totaux vs décès totaux
Calcule le pourcentage de décès par rapport au nombre total de cas, avec une analyse ciblée sur le Maroc.
***
*/

-- Looking at total cases vs total deaths

SELECT location, date, total_cases, (total_deaths/total_cases)*100 as deathpercentage  from [PortfolioProject].[dbo].[CovidDeaths]
where location  like '%Morocco%'
and continent is not null
order by 1,2

/*
***
ÉTAPE 2 — Cas totaux vs population
Calcule la part de la population touchée à partir du nombre total de cas et de la population.
***
*/

-- Looking at Total cases vs Population

SELECT location, date, Population , total_cases , (total_cases/population)*100 as Infectionpercentage  from [PortfolioProject].[dbo].[CovidDeaths]
where location  like '%Morocco%'
and continent is not null
order by 1,2

SELECT location, date, Population , total_cases , (total_cases/population)*100 as Infectionpercentage  from [PortfolioProject].[dbo].[CovidDeaths]
--where location  like '%Morocco%'
where continent is not null
order by 1,2

/*
***
ÉTAPE 3 — Pays avec les taux d'infection les plus élevés
Compare les pays selon leur nombre maximal de cas et leur pourcentage d'infection par rapport à la population.
***
*/

-- Looking at coutries with highest Infection rate compared to population

SELECT location, Population , MAX(total_cases) as HighestInfectionCount , MAX((total_cases/population))*100 as Infectionpercentage  from [PortfolioProject].[dbo].[CovidDeaths]
--where location  like '%Morocco%'
where continent is not null
group by location, Population
order by Infectionpercentage desc

/*
***
ÉTAPE 4 — Nombre de décès par pays
Agrège les décès afin d'identifier les pays présentant les nombres de décès les plus élevés.
***
*/

-- Showing Countries with highest death count per Population

SELECT location,  MAX(cast(total_deaths as int )) as TotalDeathsCount from [PortfolioProject].[dbo].[CovidDeaths]
--where location  like '%Morocco%'
where continent is not null
group by location
order by TotalDeathsCount desc

/*
***
ÉTAPE 5 — Analyse par continent
Regroupe les données par continent pour comparer les nombres de décès.
***
*/

-- Let's break things down by continents

SELECT continent,  MAX(cast(total_deaths as int )) as TotalDeathsCount from [PortfolioProject].[dbo].[CovidDeaths]
--where location  like '%Morocco%'
where continent is not null
group by continent
order by TotalDeathsCount desc

-- showing continents with the highest death count per population

SELECT location,  MAX(cast(total_deaths as int )) as TotalDeathsCount from [PortfolioProject].[dbo].[CovidDeaths]
--where location  like '%Morocco%'
where continent is null
group by location
order by TotalDeathsCount desc

/*
***
ÉTAPE 6 — Indicateurs globaux
Agrège les nouveaux cas et décès afin d'obtenir des indicateurs globaux et le pourcentage de décès.
***
*/

-- Global Numbers

SELECT  date, SUM(new_cases) as total_cases , SUM(cast(new_deaths as int )) as total_deaths , SUM(cast(new_deaths as int ))/SUM(new_cases)* 100 as deathpercentage --, total_deaths , (total_deaths/total_cases)*100 as deathpercentage
from [PortfolioProject].[dbo].[CovidDeaths]
-- where location  like '%Morocco%'
where continent is not null
group by date
order by 1,2

SELECT  SUM(new_cases) as total_cases , SUM(cast(new_deaths as int )) as total_deaths , SUM(cast(new_deaths as int ))/SUM(new_cases)* 100 as deathpercentage --, total_deaths , (total_deaths/total_cases)*100 as deathpercentage
from [PortfolioProject].[dbo].[CovidDeaths]
-- where location  like '%Morocco%'
where continent is not null
-- group by date
order by 1,2

/*
***
ÉTAPE 7 — Jointure décès et vaccinations
Joint CovidDeaths et CovidVaccinations sur la localisation et la date.
***
*/

-- Other table

Select *
from PortfolioProject.dbo.CovidDeaths dea
join PortfolioProject.dbo.CovidVaccinations vac
on dea.location = vac.location
and dea.date = vac.date

/*
***
ÉTAPE 8 — Population vs vaccinations
Utilise une fonction fenêtre pour calculer le cumul des personnes vaccinées par localisation.
***
*/

-- Looking at total population vs total vaccinations

Select dea.continent , dea.location , dea.date, dea.population , vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) over (partition by dea.location order by dea.location , dea.date) as RollingPeopleVaccinated
from PortfolioProject.dbo.CovidDeaths dea
join PortfolioProject.dbo.CovidVaccinations vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 2,3

/*
***
ÉTAPE 9 — Calcul avec une CTE
Réutilise le cumul des vaccinations dans une CTE pour calculer sa proportion par rapport à la population.
***
*/

-- USE CTE

with PopvsVac ( continent , Location , date , population , new_vaccinations , RollingPeopleVaccinated )
as
(
Select dea.continent , dea.location , dea.date, dea.population , vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) over (partition by dea.location order by dea.location , dea.date) as RollingPeopleVaccinated
from PortfolioProject.dbo.CovidDeaths dea
join PortfolioProject.dbo.CovidVaccinations vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
-- order by 2,3
)
select *, ( RollingPeopleVaccinated / population ) *100 from PopvsVac

/*
***
ÉTAPE 10 — Table temporaire
Stocke les données de vaccination dans une table temporaire pour poursuivre l'analyse.
***
*/

-- TEMP Table

Drop table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime ,
Population numeric ,
New_Vaccinations numeric ,
RollingPeopleVaccinated numeric )

Insert into #PercentPopulationVaccinated
Select dea.continent , dea.location , dea.date, dea.population , vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) over (partition by dea.location order by dea.location , dea.date) as RollingPeopleVaccinated
from PortfolioProject.dbo.CovidDeaths dea
join PortfolioProject.dbo.CovidVaccinations vac
on dea.location = vac.location
and dea.date = vac.date
--where dea.continent is not null
-- order by 2,3

select *, ( RollingPeopleVaccinated / population ) *100 from #PercentPopulationVaccinated

/*
***
ÉTAPE 11 — Création d'une View
Crée une vue SQL destinée à conserver les données préparées pour des visualisations ultérieures.
***
*/

-- Creating a View to store Data for later Visualisations
USE [PortfolioProject];
GO

Create View PercentPopulationVaccinated as
Select dea.continent , dea.location , dea.date, dea.population , vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) over (partition by dea.location order by dea.location , dea.date) as RollingPeopleVaccinated
from PortfolioProject.dbo.CovidDeaths dea
join PortfolioProject.dbo.CovidVaccinations vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
--order by 2,3

Select * from PercentPopulationVaccinated
