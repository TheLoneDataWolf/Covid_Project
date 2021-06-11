 SELECT * 
 FROM Covid_project..CovidDeaths
 ORDER BY 3,4 


 SELECT * 
 FROM Covid_project..CovidVacinations
 ORDER BY 3,4 


  ----Selecting Data that we are going to be using

  SELECT 
                  location,
		  date ,
		  total_cases,
		  new_cases,
		  total_deaths,
		  population

 FROM Covid_project..CovidDeaths
 ORDER BY 1,2 



 -- Total cases VS Total Deaths

 SELECT 
                location,
		date ,
		total_cases,
		total_deaths, 
		(total_deaths/total_cases)*100 AS Death_Percent

 FROM Covid_project..CovidDeaths
 ORDER BY 1,2
 
 -- Chances of dying from Covid in Germany. 

 SELECT 
            location,
	    date ,
	    total_cases,
	    total_deaths, 
	    (total_deaths/total_cases)*100 AS Death_Percent

 FROM Covid_project..CovidDeaths
 WHERE location LIKE '%Germany%' OR location LIKE '%Berlin%'
 ORDER BY 1,2 


 -- Total cases VS population in Germany 

 SELECT 
                location,
		date ,
		total_cases, 
		population, 
		(total_cases/population)*100 AS Percent_Population_Infected

 FROM Covid_project..CovidDeaths
 WHERE location LIKE '%Germany%' OR location LIKE '%Berlin%'
 ORDER BY 1,2 




 -- Which country has the highest infection rate compared to the population.

 SELECT 
            location,
            MAX(total_cases) AS HighestInfectionCount, 
	    population,
            MAX((total_cases/population))*100 AS  Percent_Population_Infected

 FROM Covid_project..CovidDeaths
 GROUP BY location, population
 ORDER BY 4 DESC



 -- Highest Death Count per Country and Population
 --(NOTE: total_deaths is nvarchar(255) dtype, changed it to int to perform aggregate functions)
 --(NOTE: The WHERE clause is impartant since some continent data is missing and loaction is auto_filled as continent)
  
  SELECT 
        location,
	MAX(CAST(total_deaths AS int)) AS TotalDeathCount 

 FROM Covid_project..CovidDeaths
 WHERE continent IS NOT NULL
 GROUP BY location
 ORDER BY 2 DESC




-- Highest deaths per continent


 SELECT 
        continent,
	MAX(CAST(total_deaths AS int)) AS TotalDeathCount 

 FROM Covid_project..CovidDeaths
 WHERE continent IS NOT NULL
 GROUP BY continent
 ORDER BY 2 DESC



 --  Total Worldwide Cases 

 SELECT 
	   SUM(new_cases) AS Total_New_Cases,
	   SUM(CAST(new_deaths AS int)) AS Total_New_Deaths, 
	   SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS Death_Percent

 FROM Covid_project..CovidDeaths
 WHERE continent IS NOT NULL 
 ORDER BY 1,2
 

 -- Total Worldwide Cases per day 

 SELECT 
       date,
       SUM(new_cases) AS Total_New_Cases,
       SUM(CAST(new_deaths AS int)) AS Total_New_Deaths, 
       SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS Death_Percent

 FROM Covid_project..CovidDeaths
 WHERE continent IS NOT NULL 
 GROUP BY date
 ORDER BY 1,2
 


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved the vaccine
--(NOTE: Had to convert to a float to perfrom window functions)


SELECT 
           dea.continent,
           dea.location, 
	   dea.date, 
	   dea.population, 
	   vac.new_vaccinations,
	   SUM(CONVERT(float,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date,dea.location) AS TotalPeopleVaccinated
FROM Covid_project..CovidDeaths dea
JOIN Covid_project..CovidVacinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3




-- Finding the percent vaccinated against the population using CTE.

WITH TotalPopulationVsVaccinations (continent, location, date, population, new_vaccinations, TotalPeopleVaccinated)
AS 
(
   SELECT 
              dea.continent,
              dea.location, 
	      dea.date, 
	      dea.population, 
	      vac.new_vaccinations,
	      SUM(CONVERT(float,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date,dea.location) AS TotalPeopleVaccinated
   FROM Covid_project..CovidDeaths dea
   JOIN Covid_project..CovidVacinations vac
   ON dea.location = vac.location
   AND dea.date = vac.date
   WHERE dea.continent IS NOT NULL
 
)
   SELECT 
          *,
		  (TotalPeopleVaccinated/population)* 100 AS Percent_Vaccinated
   FROM TotalPopulationVsVaccinations



   -- Alternative Way For The Same Query Above Using TEMP tables

   DROP TABLE IF EXISTS #TotalPopulationVsVaccinations
   CREATE TABLE #TotalPopulationVsVaccinations
   ( 
          continent nvarchar(255),
	  location nvarchar(255),
	  date datetime,
	  population numeric,
	  new_vaccinations numeric,
	  TotalPeopleVaccinated numeric
	)

	INSERT INTO #TotalPopulationVsVaccinations
	SELECT 
              dea.continent,
              dea.location, 
	      dea.date, 
	      dea.population, 
	      vac.new_vaccinations,
	      SUM(CONVERT(float,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date,dea.location) AS TotalPeopleVaccinated
   FROM Covid_project..CovidDeaths dea
   JOIN Covid_project..CovidVacinations vac
   ON dea.location = vac.location
   AND dea.date = vac.date
 

   SELECT 
          *,
          (TotalPeopleVaccinated/population)* 100 AS Percent_Vaccinated
   FROM #TotalPopulationVsVaccinations








   -- Creating A Virtual Table Using View For Later Visualizations
 
 
 GO
CREATE VIEW TotalPopulationVsVaccinations AS 
   
   SELECT 
              dea.continent,
              dea.location, 
	      dea.date, 
	      dea.population, 
	      vac.new_vaccinations,
	      SUM(CONVERT(float,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date,dea.location) AS TotalPeopleVaccinated
   FROM Covid_project..CovidDeaths dea
   JOIN Covid_project..CovidVacinations vac
   ON dea.location = vac.location
   AND dea.date = vac.date
   WHERE dea.continent IS NOT NULL
