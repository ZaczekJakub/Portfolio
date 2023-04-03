--Data preview

SELECT *
From PortfolioCovid.dbo.PopulationData
order by 3,5

SELECT *
From PortfolioCovid.dbo.Deaths
order by location,5

SELECT *
From PortfolioCovid.dbo.Vaccinations
order by 3,5

--Updating date format

Alter table Deaths
Add DateNew date;

Update Deaths
Set DateNew = convert(date,date)
From PortfolioCovid.dbo.Deaths

Alter table Vaccinations
Add DateNew date;

Update Vaccinations
Set DateNew = convert(date,date)
From PortfolioCovid.dbo.Vaccinations

Alter table PopulationData
Add DateNew date;

Update PopulationData
Set DateNew = convert(date,date)
From PortfolioCovid.dbo.PopulationData

Alter Table Deaths
drop column date

Alter Table Vaccinations
drop column date

Alter Table PopulationData
drop column date



--Deaths Vs Cases % by country WithClause

With DeathsVsCasesCountry as
(
Select
location, max(total_cases) as TotalCases, max(total_deaths) as TotalDeaths
From PortfolioCovid.dbo.Deaths
group by location
)
Select 
location, (TotalDeaths/TotalCases)*100 as DeathsVsCases
From DeathsVsCasesCountry
--Where location = 'Poland'

Select *
from DeathsVsCasesCountry
order by 2 desc

--Deaths Vs Cases % by continent #temp_table

Drop Table if exists #DeathsVsCasesContinent
Create Table #DeathsVsCasesContinent
(continent nvarchar(255),
TotalCases numeric,
TotalDeaths numeric
)

Insert into #DeathsVsCasesContinent 
Select
tab1.continent, 
sum(tab1.TotalCases) as TotalCases, 
sum(tab1.totalDeaths) as TotalDeaths
From 
	(select
		continent,
		location,
		max(total_cases) as TotalCases, 
		max(total_deaths) as TotalDeaths
	from PortfolioCovid.dbo.Deaths
	group by continent,location
	) tab1
group by continent

Select 
continent, convert(float,round((TotalDeaths/TotalCases)*100,3)) as DeathsVsCases
From #DeathsVsCasesContinent
order by 2 desc



--Total Cases and Deaths Vs PopulationDensity

Select
dea.location as Country, max(dea.population) as Population, max(pop.population_density) as Density, max(dea.total_cases) as TotalCases, max(dea.total_deaths) as TotalDeaths,
max(round(dea.total_cases/pop.population_density,2)) as CasesDensity, max(round(dea.total_deaths/pop.population_density,2)) as DeathsDensity
From PortfolioCovid.dbo.Deaths dea
	join PortfolioCovid.dbo.PopulationData pop
	on dea.location = pop.location
	and dea.iso_code = pop.iso_code
	and dea.DateNew = pop.DateNew
	group by dea.location
Order By DeathsDensity desc

--Cases and Deaths Asc # over()
Drop table if exists #AcumulatedCasesAndDeaths
Create Table #AcumulatedCasesAndDeaths
(
location nvarchar(255),
datenew date,
new_cases numeric,
AcumulatedNewCases numeric,
new_deaths numeric,
AsumulatedNewDeaths numeric)

Insert into #AcumulatedCasesAndDeaths
Select
	location, 
	DateNew, 
	new_cases, 
		sum(new_cases) over (partition by location
						order by location,datenew) as AcumulatedNewCases,
	new_deaths, 
	sum(new_deaths) over (partition by location
						order by location,datenew) as AcumulatedNewDeaths
From PortfolioCovid.dbo.Deaths

Select *
From #AcumulatedCasesAndDeaths


--Vaccinations Country
create procedure PercentOfPopulationVaccinated
as
drop table if exists #PercentOfVac
Create Table #PercentOfVac
(location nvarchar(255),
datenew date,
NewVac numeric,
AccumulatedVacc numeric,
population numeric)

Insert into #PercentOfVac
SELECT 
	vac.location as location,
	vac.DateNew as date,
	vac.new_vaccinations as NewVac, 
	sum(vac.new_vaccinations) over (partition by vac.location
									order by vac.location, vac.datenew) as AccumulatedVacc,
	vac.population as population
From PortfolioCovid.dbo.Vaccinations vac

Select
	location,
	datenew,
	NewVac,
	AccumulatedVacc,
	AccumulatedVacc/population*100 as PercentageOfPopulation
From #PercentOfVac
order by 5 desc

EXEC PercentOfPopulationVaccinated

--Procedure with parametr

Create procedure TableVacProcedure 
@location nvarchar(255)
as
drop table if exists #VacTable
Create Table #VacTable
(location nvarchar(255),
datenew date,
NewVaccination numeric,
AccuVacc numeric)

Insert into #VacTable
SELECT 
	vac.location,
	vac.DateNew, 
	vac.new_vaccinations, 
	sum(vac.new_vaccinations) over (partition by vac.location
									order by vac.location, vac.datenew) as NewVacs
From PortfolioCovid.dbo.Vaccinations vac
		join PortfolioCovid.dbo.Deaths dea 
		on vac.iso_code = dea.iso_code
		and vac.location = dea.location
		and vac.DateNew = dea.DateNew
Where vac.location = @location

Select *
From #VacTable

Exec TableVacProcedure @location = 'Poland'

--Country Population table

Drop table if exists #CountryPopulationTable
Create table #CountryPopulationTable
(	location nvarchar(255),
	CountryPopulation numeric
)
insert into #CountryPopulationTable
		select distinct 
			location,
			max(population) over (partition by location
								  order by location) as CountryPopulation
		from PortfolioCovid.dbo.Deaths

Select *
from #CountryPopulationTable
order by 2 desc

--Continent Population Table

Drop table if exists #ContinentsPopulationTable
Create Table #ContinentsPopulationTable
(
continent nvarchar(255),
ContinentPopulation numeric
)
insert into #ContinentsPopulationTable
Select
	continent,
	Sum(distinct CountryPopulation)
from PortfolioCovid.dbo.Deaths dea
join #CountryPopulationTable cou on dea.location = cou.location
group by continent

select *
from #ContinentsPopulationTable
order by 2 desc

--Countries Total numbers
Drop table if exists #CountryTotalNumbers
Create table #CountryTotalNumbers
(	location nvarchar(255),
	TotalDeaths numeric,
	TotalCases numeric,
	TotalVaccinations numeric
)
insert into #CountryTotalNumbers
		select distinct 
			dea.location,
			max(total_deaths) over (partition by dea.location
									order by dea.location),
			max(total_cases) over (partition by dea.location
									order by dea.location),
			max(total_vaccinations) over (partition by dea.location
									order by dea.location)
		from PortfolioCovid.dbo.Deaths dea
		join PortfolioCovid.dbo.Vaccinations vac on dea.location = vac.location
												 and dea.datenew = vac.datenew
												 and dea.continent = vac.continent

Select *
from #CountryTotalNumbers
order by 2 desc

--Continents Total numbers

Drop table if exists #ContinentsTotalNumbers
Create table #ContinentsTotalNumbers
(	continents nvarchar(255),
	TotalDeaths numeric,
	TotalCases numeric,
	TotalVaccinations numeric
)
insert into #ContinentsTotalNumbers
		select distinct
			dea.continent,
			sum(distinct cou.TotalDeaths), 
			sum(distinct cou.TotalCases),
			sum(distinct cou.TotalVaccinations)
		from PortfolioCovid.dbo.Deaths dea
		join #CountryTotalNumbers cou on dea.location = cou.location
		group by dea.continent
Select *
from #ContinentsTotalNumbers
order by 2 desc

--Countries percentage deaths, cases and vaccinations
Drop table if exists #CountryPercentageTotals
Create Table #CountryPercentageTotals
(
location nvarchar(255),
PercentageDeaths float,
PercentageCases float,
PercentageVaccination float,
PercentageDeathsVsCases float)

Insert into #CountryPercentageTotals
Select
	ctn.location,
	convert(float,round(ctn.TotalDeaths/cpt.CountryPopulation*100,3)),
	convert(float,round(ctn.TotalCases/cpt.CountryPopulation*100,3)),
	convert(float,round(ctn.TotalVaccinations/cpt.CountryPopulation*100,3)),
	convert(float,round(ctn.TotalDeaths/ctn.TotalCases*100,3))
from #CountryTotalNumbers ctn 
join #CountryPopulationTable cpt on ctn.location = cpt.location

Select *
from #CountryPercentageTotals
order by 2 desc


--Continents percentage of deaths, cases and vaccinations

Drop table if exists #ContinentsPercentTotals
Create table #ContinentsPercentTotals
(
continent nvarchar(255),
populations numeric,
PercentDeaths float,
PercentCases float,
PercentVaccinations float,
PercentDeathVsCases float
)
Insert into #ContinentsPercentTotals
Select
	cpt.continent,
	cpt.ContinentPopulation,
	convert(float,round((ctn.TotalDeaths/cpt.ContinentPopulation)*100,3)) as ProcentDeaths,
	convert(float,round((ctn.TotalCases/cpt.ContinentPopulation)*100,3)) as ProcentCases, 
	convert(float,round((ctn.TotalVaccinations/cpt.ContinentPopulation)*100,3)) as ProcentVaccinations, 
	convert(float,round((ctn.TotalDeaths/ctn.TotalCases)*100,3)) as ProcentDeathsVsCases
from #ContinentsPopulationTable cpt
join #ContinentsTotalNumbers ctn on cpt.continent = ctn.continents


Select *
from #ContinentsPercentTotals
order by 6 desc

--WorldNumbers
with WorldNumber as(
Select 
	 sum(cpt.ContinentPopulation) as WorldPopulation,
	 sum(con.TotalCases) as WorldCases, 
	 sum(con.TotalDeaths) as WorldDeaths,
	 sum(con.TotalVaccinations) as WorldVaccinations
From #ContinentsTotalNumbers con
join #ContinentsPopulationTable cpt on cpt.continent = con.continents
)
Select
	WorldPopulation,
	WorldCases,
	convert(float,round(WorldCases/WorldPopulation*100,3)) as ProcCases,
	WorldDeaths,
	convert(float,round(WorldDeaths/WorldPopulation*100,3)) as ProcDeaths,
	WorldVaccinations,
	convert(float,round(WorldVaccinations/WorldPopulation*100,3)) as ProcVacs,
	convert(float,round(WorldDeaths/WorldCases*100,3)) as ProcDeathVsCases
From WorldNumber
	





