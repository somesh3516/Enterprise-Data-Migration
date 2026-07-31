/*
===============================================================================
Enterprise Data Migration
02 - Import Legacy Customer Data
===============================================================================

Purpose:
    Imports the generated legacy customer CSV into the source-system table and
    records the import results in the migration log.
===============================================================================
*/

USE enterprise_data_migration;

TRUNCATE TABLE legacy_customers;

LOAD DATA LOCAL INFILE
    'C:/Users/somehs/Documents/GitHub/Enterprise-Data-Migration/data/raw/legacy_customers.csv'
INTO TABLE legacy_customers
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    legacy_customer_id,
    external_id,
    first_name,
    last_name,
    email,
    phone,
    birth_date,
    street_address,
    city,
    state,
    zip_code,
    customer_status,
    created_date
);

INSERT INTO migration_log (
    migration_name,
    source_table,
    target_table,
    records_processed,
    records_loaded,
    records_failed,
    status,
    started_at,
    completed_at,
    notes
)
SELECT
    'Legacy customer CSV import',
    'legacy_customers.csv',
    'legacy_customers',
    COUNT(*),
    COUNT(*),
    0,
    'Completed',
    NOW(),
    NOW(),
    'Initial legacy CRM data import'
FROM legacy_customers;

SELECT COUNT(*) AS imported_records
FROM legacy_customers;

SELECT *
FROM migration_log
ORDER BY migration_id DESC
LIMIT 1;