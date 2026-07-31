/*
===============================================================================
Enterprise Data Migration
06 - Reconciliation
===============================================================================

Purpose:
    Compares source, staging, rejected, and target record counts and calculates
    the migration success rate.
===============================================================================
*/

USE enterprise_data_migration;


/* ---------------------------------------------------------------------------
   Reconciliation summary
--------------------------------------------------------------------------- */

SELECT
    source.total_source_records,
    staging.total_staging_records,
    staging.valid_staging_records,
    staging.rejected_staging_records,
    target.total_target_records,

    source.total_source_records - target.total_target_records
        AS source_to_target_difference,

    ROUND(
        (
            target.total_target_records /
            NULLIF(source.total_source_records, 0)
        ) * 100,
        2
    ) AS migration_success_rate,

    CASE
        WHEN source.total_source_records =
             staging.valid_staging_records + staging.rejected_staging_records
         AND staging.total_staging_records = source.total_source_records
         AND target.total_target_records = staging.valid_staging_records
            THEN 'Reconciled'
        ELSE 'Mismatch'
    END AS reconciliation_status

FROM
    (
        SELECT COUNT(*) AS total_source_records
        FROM legacy_customers
    ) AS source

CROSS JOIN
    (
        SELECT
            COUNT(*) AS total_staging_records,
            SUM(validation_status = 'Valid') AS valid_staging_records,
            SUM(validation_status = 'Rejected') AS rejected_staging_records
        FROM staging_customers
    ) AS staging

CROSS JOIN
    (
        SELECT COUNT(*) AS total_target_records
        FROM salesforce_customers
    ) AS target;


/* ---------------------------------------------------------------------------
   Validation-error breakdown
--------------------------------------------------------------------------- */

SELECT
    validation_rule,
    COUNT(*) AS failed_rule_count
FROM validation_results
GROUP BY validation_rule
ORDER BY failed_rule_count DESC;


/* ---------------------------------------------------------------------------
   Customers failing multiple validation rules
--------------------------------------------------------------------------- */

SELECT
    legacy_customer_id,
    COUNT(*) AS failed_rule_count,
    GROUP_CONCAT(
        validation_rule
        ORDER BY validation_rule
        SEPARATOR '; '
    ) AS failed_rules
FROM validation_results
GROUP BY legacy_customer_id
HAVING COUNT(*) > 1
ORDER BY failed_rule_count DESC, legacy_customer_id
LIMIT 25;


/* ---------------------------------------------------------------------------
   Confirm rejected records were excluded from target
--------------------------------------------------------------------------- */

SELECT
    COUNT(*) AS rejected_records_loaded_to_target
FROM staging_customers AS sc
INNER JOIN salesforce_customers AS sf
    ON sc.legacy_customer_id = sf.legacy_customer_id
WHERE sc.validation_status = 'Rejected';


/* ---------------------------------------------------------------------------
   Confirm valid records were loaded to target
--------------------------------------------------------------------------- */

SELECT
    COUNT(*) AS valid_records_missing_from_target
FROM staging_customers AS sc
LEFT JOIN salesforce_customers AS sf
    ON sc.legacy_customer_id = sf.legacy_customer_id
WHERE sc.validation_status = 'Valid'
  AND sf.legacy_customer_id IS NULL;