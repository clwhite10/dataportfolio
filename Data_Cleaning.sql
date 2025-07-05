USE world_layoffs;

-- Examining the information
SELECT * 
FROM layoffs;

-- Set-up
/* 
	Creating a back up table that will be edited.
    Using this table means if there are any issues the 
    back up table still exists
*/
-- Create the table to be edited based on the raw data table
CREATE TABLE layoffs_staging
LIKE layoffs;

-- Check to see if the table has been created correctly
SELECT * 
FROM layoffs_staging;

/*
	Insert the information from the raw data table into the table to 
	be edited
*/
INSERT layoffs_staging
SELECT *
FROM layoffs;

-- STEP 1 - Remove Duplicates

-- Creating a CTE to check for any duplicates, any duplicates will get a row_num
-- value of 2
WITH duplicate_cte AS
(
	SELECT *,
	ROW_NUMBER() OVER(
		PARTITION BY company, location, 
			industry, total_laid_off, percentage_laid_off, `date`, stage, 
            country, funds_raised_millions) AS row_num
	FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

/*
	Double checking the duplicates to make sure each one in the CTE 
	is an actual duplicate so we will check one of the companies that returned 
    a row number of 2, indicating a duplicate
*/
-- Checking an individual company 
SELECT *
FROM layoffs_staging
WHERE company = 'Casper';

-- Creating another staging table to delete duplicates based on Row numbers
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Checks
SELECT *
FROM layoffs_staging2;

-- Insert data
INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
	PARTITION BY company, location, 
		industry, total_laid_off, percentage_laid_off, `date`, stage, 
		country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- Filter
SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

-- Deleting duplicates from the second staging table
DELETE
FROM layoffs_staging2
WHERE row_num > 1;

-- Filter after delete
SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

-- STEP 2 - Standardise the data
-- Finding issues in the data and fixing them

-- Company
-- Trimming whitespace from Company name and updating the table
SELECT company, TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

-- Industry
/*
	Taking the lists of distinct industries and ordering them
	by the column itself
*/
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;

-- Changing the Crypto industry labels that included
-- three different labels to just one
SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- Location
SELECT DISTINCT location
FROM layoffs_staging2
ORDER BY 1;

-- Country
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;

-- United States has two entries, one with a full stop at the end
SELECT *
FROM layoffs_staging2
WHERE country LIKE 'United States_'
ORDER BY 1;

-- Trimming something that is not a white space but a symbol instead
-- This will trim the full stop from the United States value 
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- Date
/*
	The date column is currently set to text if EDA requires Time Series
	it will need to be changed.
*/
-- Setting the date column to a date format
SELECT `date`,
STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging2;

-- Update date column with new date format
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- Checks
SELECT `date`
FROM layoffs_staging2;

-- Only do this on staging tables
-- Modifying date column to DATE type
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- Checks
SELECT *
FROM layoffs_staging2;

-- STEP 3 - Null or Blank values
-- Checking industry values
SELECT * 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Looking for the NULL or blank values
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL 
	OR industry = '';

-- By looking at specific companies, there are 
-- other companies that have the a populated industry
SELECT *
FROM layoffs_staging2
WHERE company = "Airbnb";

-- Updating the blank values to NULL will help the UPDATE statment
-- due to having actual information
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

-- This will compare the blank vs the populated industries
SELECT t1.industry, t2.industry
FROM layoffs_staging2 AS t1
JOIN layoffs_staging2 AS t2
	ON t1.company = t2.company
    AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry = '') 
	AND t2.industry IS NOT NULL;

-- Updating the table to take the populated industries and 
-- fill in the blank values of the same company
UPDATE layoffs_staging2 AS t1
JOIN layoffs_staging2 AS t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL 
	AND t2.industry IS NOT NULL;
    
/* 
	Other columns like total_laid_off, percentage_laid_off, and 
    funds_raised_millions can't be changed because other data is needed
    If company totals before layoffs were present in the data, calculations
    could be performed to work out the percentage and total
    Funds raised could be done with some web scraping but is not applicable to this
    tutorial.
*/

-- STEP 4 - Remove any columns
SELECT * 
FROM layoffs_staging2
WHERE total_laid_off IS NULL 
	AND percentage_laid_off IS NULL;
/*
	Due to the nature of the EDA, which will use the total and percentage
    laid off columns, the companies where both of the values are null can be removed
    because there isn't a good means of use for these columns
*/
-- Deleting from the table where both the total and percentage laid off 
-- are null 
DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL 
	AND percentage_laid_off IS NULL;

-- Checks
SELECT *
FROM layoffs_staging2;

-- Removing the row_num column
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

-- End of Data Cleaning