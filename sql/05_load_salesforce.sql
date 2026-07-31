/*
===============================================================================
Enterprise Data Migration
05 - Load Valid Records into Salesforce Target
===============================================================================

Purpose:
    Loads only validated staging records into the simulated Salesforce target
    table and records the migration results in the migration log.
===============================================================================
*/

USE enterprise_data_migration;


/* ---------------------------------------------------------------------------
   Reset target table for repeatable testing
--------------------------------------------------------------------------- */

TRUNCATE TABLE salesforce_customers;


/* ---------------------------------------------------------------------------
   Load valid records into the target system
--------------------------------------------------------------------------- */

INSERT INTO salesforce_customers (
    legacy_customer_id,
    external_id,
    full_name,
    email,
    phone,
    birth_date,
    mailing_street,
    mailing_city,
    mailing_state,
    mailing_postal_code,
    account_status,
    source_created_date
)
SELECT
    legacy_customer_id,
    external_id,
    CONCAT_WS(
        ' ',
        NULLIF(TRIM(first_name), ''),
        NULLIF(TRIM(last_name), '')
    ) AS full_name,
    LOWER(TRIM(email)) AS email,
    phone,
    birth_date,
    TRIM(street_address) AS mailing_street,
    TRIM(city) AS mailing_city,
    UPPER(TRIM(state)) AS mailing_state,
    TRIM(zip_code) AS mailing_postal_code,
    customer_status AS account_status,
    created_date AS source_created_date
FROM staging_customers
WHERE validation_status = 'Valid';


/* ---------------------------------------------------------------------------
   Log the target load
--------------------------------------------------------------------------- */

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
    'Salesforce customer target load',
    'staging_customers',
    'salesforce_customers',
    COUNT(*) AS records_processed,
    SUM(validation_status = 'Valid') AS records_loaded,
    SUM(validation_status = 'Rejected') AS records_failed,
    CASE
        WHEN SUM(validation_status = 'Valid') > 0
            THEN 'Completed'
        ELSE 'Failed'
    END AS status,
    NOW(),
    NOW(),
    CONCAT(
        SUM(validation_status = 'Valid'),
        ' valid records loaded; ',
        SUM(validation_status = 'Rejected'),
        ' rejected records excluded'
    )
FROM staging_customers;


/* ---------------------------------------------------------------------------
   Target load validation
--------------------------------------------------------------------------- */

SELECT
    COUNT(*) AS total_salesforce_customers
FROM salesforce_customers;


SELECT
    validation_status,
    COUNT(*) AS staging_record_count
FROM staging_customers
GROUP BY validation_status;


SELECT
    migration_id,
    migration_name,
    records_processed,
    records_loaded,
    records_failed,
    status,
    completed_at,
    notes
FROM migration_log
ORDER BY migration_id DESC
LIMIT 1;


/* ---------------------------------------------------------------------------
   Preview migrated records
--------------------------------------------------------------------------- */

SELECT
    salesforce_id,
    legacy_customer_id,
    full_name,
    email,
    phone,
    mailing_city,
    mailing_state,
    mailing_postal_code,
    account_status,
    migrated_at
FROM salesforce_customers
ORDER BY salesforce_id
LIMIT 20;