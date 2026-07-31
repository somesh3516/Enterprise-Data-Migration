/*
===============================================================================
Enterprise Data Migration
04 - Transform Valid Records into Staging
===============================================================================

Purpose:
    Loads source records into the staging table, standardizes values, and marks
    each record as Valid or Rejected based on validation results.
===============================================================================
*/

USE enterprise_data_migration;

TRUNCATE TABLE staging_customers;

INSERT INTO staging_customers (
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
    created_date,
    validation_status,
    validation_message
)
SELECT
    lc.legacy_customer_id,
    lc.external_id,
    TRIM(lc.first_name),
    TRIM(lc.last_name),
    LOWER(TRIM(lc.email)),
    CASE
        WHEN lc.phone IS NULL OR TRIM(lc.phone) = ''
            THEN NULL
        ELSE REGEXP_REPLACE(lc.phone, '[^0-9]', '')
    END,
    lc.birth_date,
    TRIM(lc.street_address),
    TRIM(lc.city),
    UPPER(TRIM(lc.state)),
    TRIM(lc.zip_code),
    CASE
        WHEN UPPER(TRIM(lc.customer_status)) = 'ACTIVE'
            THEN 'Active'
        WHEN UPPER(TRIM(lc.customer_status)) = 'INACTIVE'
            THEN 'Inactive'
        ELSE 'Unknown'
    END,
    lc.created_date,
    CASE
        WHEN vr.legacy_customer_id IS NULL
            THEN 'Valid'
        ELSE 'Rejected'
    END,
    CASE
        WHEN vr.legacy_customer_id IS NULL
            THEN NULL
        ELSE vr.validation_messages
    END
FROM legacy_customers AS lc
LEFT JOIN (
    SELECT
        legacy_customer_id,
        GROUP_CONCAT(
            DISTINCT validation_message
            ORDER BY validation_message
            SEPARATOR '; '
        ) AS validation_messages
    FROM validation_results
    GROUP BY legacy_customer_id
) AS vr
    ON lc.legacy_customer_id = vr.legacy_customer_id;


/* Staging summary */
SELECT
    validation_status,
    COUNT(*) AS record_count
FROM staging_customers
GROUP BY validation_status;


/* Preview rejected records */
SELECT
    legacy_customer_id,
    email,
    phone,
    state,
    zip_code,
    validation_message
FROM staging_customers
WHERE validation_status = 'Rejected'
LIMIT 20;