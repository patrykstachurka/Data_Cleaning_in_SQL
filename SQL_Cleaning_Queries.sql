-- Creating id column which serves as a Primary Key

ALTER TABLE layoffs ADD COLUMN id SERIAL;

CREATE TABLE layoffs_stage AS
SELECT id, company, location, industry, total_laid_off, percentage_laid_off, date, stage, country, funds_raised_millions
FROM layoffs;

ALTER TABLE layoffs_stage ADD PRIMARY KEY (id);


-- Removing duplicates

SELECT *,
ROW_NUMBER() OVER (
	PARTITION BY company, "location", industry, total_laid_off, "date", stage, country, funds_raised_millions
	ORDER BY company
	) AS row_num
FROM layoffs_stage;

WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER (
	PARTITION BY company, "location", industry, total_laid_off, "date", stage, country, funds_raised_millions
	ORDER BY company
	) AS row_num
FROM layoffs_stage
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

DELETE 
FROM layoffs_stage WHERE id IN (2360, 1492, 2359, 626, 2358);


-- Standardizing Data

UPDATE layoffs_stage
SET company = TRIM(company);

UPDATE layoffs_stage
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

UPDATE layoffs_stage
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- "Date" column data type change

ALTER TABLE layoffs_stage ADD COLUMN date_temp DATE;

SELECT * FROM layoffs_stage;

UPDATE layoffs_stage
SET date_temp = 
	CASE
		WHEN "date" ~ '^\d{4}-\d{2}-\d{2}$' THEN "date"::date
		WHEN "date" ~ '^\d{1,2}/\d{1,2}/\d{4}$' THEN to_date("date", 'MM/DD/YYYY')
	ELSE NULL
END;


ALTER TABLE layoffs_stage DROP COLUMN "date";

ALTER TABLE layoffs_stage RENAME COLUMN date_temp TO "date";


-- "total_laid_off" data type change

SELECT DISTINCT "total_laid_off"
FROM layoffs_stage
WHERE "total_laid_off" !~ '^\d+$';

UPDATE layoffs_stage
SET "total_laid_off" = NULL
WHERE "total_laid_off" !~ '^\d+$';

ALTER TABLE layoffs_stage
ALTER COLUMN "total_laid_off" TYPE INT
USING "total_laid_off"::integer;


-- Blank/Null values

SELECT * 
FROM layoffs_stage
WHERE total_laid_off IS NULL
AND
percentage_laid_off IS NULL;

UPDATE layoffs_stage
SET funds_raised_millions = NULL
WHERE funds_raised_millions = '';

UPDATE layoffs_stage
SET industry = NULL
WHERE industry = '';

SELECT t1.industry, t2.industry
FROM layoffs_stage t1
JOIN layoffs_stage t2
ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

UPDATE layoffs_stage t1
SET industry = t2.industry
FROM layoffs_stage t2
WHERE t1.company = t2.company
AND t1.industry IS NULL
AND t2.industry IS NOT NULL;

DELETE 
FROM layoffs_stage
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;


