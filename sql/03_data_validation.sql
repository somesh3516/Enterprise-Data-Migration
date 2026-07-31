/*
===============================================================================
Enterprise Data Migration
03 - Data Validation
===============================================================================

Purpose:
    Identifies source-data quality issues and stores rule-level results in the
    validation_results table.
===============================================================================
*/

USE enterprise_data_migration;

TRUNCATE TABLE validation_results;


/* Missing email */
INSERT INTO validation_results (
    legacy_customer_id,
    validation_rule,
    validation_result,
    validation_message
)
SELECT
    legacy_customer_id,
    'Email Required',
    'Failed',
    'Email is missing'
FROM legacy_customers
WHERE email IS NULL
   OR TRIM(email) = '';


/* Invalid email format */
INSERT INTO validation_results (
    legacy_customer_id,
    validation_rule,
    validation_result,
    validation_message
)
SELECT
    legacy_customer_id,
    'Email Format',
    'Failed',
    CONCAT('Invalid email format: ', email)
FROM legacy_customers
WHERE email IS NOT NULL
  AND TRIM(email) <> ''
  AND email NOT REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$';


/* Missing phone */
INSERT INTO validation_results (
    legacy_customer_id,
    validation_rule,
    validation_result,
    validation_message
)
SELECT
    legacy_customer_id,
    'Phone Required',
    'Failed',
    'Phone number is missing'
FROM legacy_customers
WHERE phone IS NULL
   OR TRIM(phone) = '';


/* Invalid state */
INSERT INTO validation_results (
    legacy_customer_id,
    validation_rule,
    validation_result,
    validation_message
)
SELECT
    legacy_customer_id,
    'State Validation',
    'Failed',
    CONCAT('Invalid state code: ', state)
FROM legacy_customers
WHERE state NOT IN ('VA', 'NC', 'GA', 'MD', 'PA');


/* Invalid ZIP code */
INSERT INTO validation_results (
    legacy_customer_id,
    validation_rule,
    validation_result,
    validation_message
)
SELECT
    legacy_customer_id,
    'ZIP Code Format',
    'Failed',
    CONCAT('Invalid ZIP code: ', zip_code)
FROM legacy_customers
WHERE zip_code NOT REGEXP '^[0-9]{5}$';


/* Duplicate email */
INSERT INTO validation_results (
    legacy_customer_id,
    validation_rule,
    validation_result,
    validation_message
)
SELECT
    lc.legacy_customer_id,
    'Duplicate Email',
    'Failed',
    CONCAT('Duplicate email: ', lc.email)
FROM legacy_customers AS lc
INNER JOIN (
    SELECT email
    FROM legacy_customers
    WHERE email IS NOT NULL
      AND TRIM(email) <> ''
    GROUP BY email
    HAVING COUNT(*) > 1
) AS duplicates
    ON lc.email = duplicates.email;


/* Validation summary */
SELECT
    validation_rule,
    COUNT(*) AS failed_records
FROM validation_results
GROUP BY validation_rule
ORDER BY failed_records DESC;


/* Total failed records */
SELECT
    COUNT(DISTINCT legacy_customer_id) AS customers_with_validation_errors
FROM validation_results;