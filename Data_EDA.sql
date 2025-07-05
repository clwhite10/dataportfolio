-- Exploratory Data Analysis
USE world_layoffs;

-- Total laid off figures
-- The Max total layoffs and max percentage layoffs 
SELECT 
	MAX(total_laid_off),
    MAX(percentage_laid_off)
    # 1 means the company closed
FROM layoffs_staging2;

-- Ordering all companies with a percentage of 100%
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY
	total_laid_off DESC;

-- Ordering the 100% layoffs by the amount of money raised
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY
	funds_raised_millions DESC;

-- Sum off layoffs by company ordered by the sum
SELECT 
	company,
    SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY
	company
ORDER BY
	2 DESC;

-- Date ranges
SELECT 
	MIN(`date`),
    MAX(`date`)
FROM layoffs_staging2;

-- Total layoffs by industry ordered by the sum total
SELECT 
	industry,
    SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY
	industry
ORDER BY
	2 DESC;

-- Total layoffs by country ordered by the sum total
SELECT 
	country,
	SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY
	country
ORDER BY
	2 DESC;

-- Sum of layoffs by year ordered by the year
SELECT
	YEAR(`date`),
    SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY
	YEAR(`date`)
ORDER BY 
	 1 DESC;
     
-- Sum of layoffs by Stage ordered by sum total
SELECT
	stage,
	SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY
	stage
ORDER BY
	2 DESC;
    
-- Progression of layoffs
-- Rolling total layoffs based on Month 
/* 
	This CTE sets up the date column to use the month and then adds each 
	total of layoffs from that month to the previous month
*/
WITH Rolling_Total AS 
(
	SELECT 
		SUBSTRING(`date`, 1, 7) AS `month`,
		SUM(total_laid_off) AS total_laid_off
	FROM layoffs_staging2
	WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
	GROUP BY 
		`month`
	ORDER BY
		`month`
)
SELECT 
	`month`, 
    total_laid_off,
    SUM(total_laid_off) OVER(ORDER BY `month`) AS rolling_total
FROM Rolling_Total;

-- Company layoffs by year
/*
	This set of statements starts by outlining the sum total of layoffs by company
    then looks at each company layoff by the year for example the company 'Loft' 
    had layoffs in 2020, 2022, and 2023
*/
SELECT 
	company,
    SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY
	company
ORDER BY
	2 DESC;
    
SELECT 
	company,
    YEAR(`date`),
    SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY
	company,
    YEAR(`date`)
ORDER BY 
	3 DESC;

-- Top 5 company ranking over in each year
/* 
	These two CTEs take the companies by year and total layoffs, adds a DENSE RANK 
    by years.
    The SELECT statement utilising the DENSE RANK shows the companies ranked 1 to 5
    showing and also showing any company that duplicates rank for example, Amazon and 
    Salesforce are both ranked 4 in 2023
*/
WITH Company_Year(Company, Years, total_laid_off) AS 
(
	SELECT 
		company,
		YEAR(`date`),
		SUM(total_laid_off)
	FROM layoffs_staging2
	GROUP BY
		company,
		YEAR(`date`)
), Company_Year_Rank AS
(
	SELECT *,
		DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS Ranking
	FROM Company_Year
	WHERE years IS NOT NULL
)
SELECT *
FROM Company_Year_Rank
WHERE Ranking <= 5
ORDER BY
	Years;
