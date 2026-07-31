/*
===============================================================================
Enterprise Data Migration
08 - Final Validation Queries
===============================================================================

Purpose:
    Performs final integrity, quality, transformation, and reconciliation checks
    across the complete migration pipeline.
===============================================================================
*/

USE enterprise_data_migration;


/* 1. Record counts across migration layers */

SELECT
    (SELECT COUNT(*) FROM legacy_customers) AS source_records,
    (SELECT COUNT(*) FROM staging_customers) AS staging_records,
    (
        SELECT COUNT(*)
        FROM staging_customers
        WHERE validation_status = 'Valid'
    ) AS valid_staging_records,
    (
        SELECT COUNT(*)
        FROM staging_customers
        WHERE validation_status = 'Rejected'
    ) AS rejected_staging_records,
    (SELECT COUNT(*) FROM salesforce_customers) AS target_records;


/* 2. Reconciliation status */

SELECT *
FROM vw_reconciliation_summary;


/* 3. Data-quality scorecard */

SELECT *
FROM vw_data_quality_scorecard
ORDER BY pass_rate_percent;


/* 4. Validation-rule totals */

SELECT
    validation_rule,
    COUNT(*) AS failed_rule_count
FROM validation_results
GROUP BY validation_rule
ORDER BY failed_rule_count DESC;


/* 5. Unique customers with validation failures */

SELECT
    COUNT(DISTINCT legacy_customer_id)
        AS customers_with_validation_errors
FROM validation_results;


/* 6. Confirm rejected records were not migrated */

SELECT
    COUNT(*) AS rejected_records_in_target
FROM staging_customers AS sc
INNER JOIN salesforce_customers AS sf
    ON sc.legacy_customer_id = sf.legacy_customer_id
WHERE sc.validation_status = 'Rejected';


/* 7. Confirm every valid record was migrated */

SELECT
    COUNT(*) AS valid_records_missing_from_target
FROM staging_customers AS sc
LEFT JOIN salesforce_customers AS sf
    ON sc.legacy_customer_id = sf.legacy_customer_id
WHERE sc.validation_status = 'Valid'
  AND sf.legacy_customer_id IS NULL;


/* 8. Check target uniqueness */

SELECT
    legacy_customer_id,
    COUNT(*) AS duplicate_count
FROM salesforce_customers
GROUP BY legacy_customer_id
HAVING COUNT(*) > 1;


/* 9. Check required target fields */

SELECT
    COUNT(*) AS target_records_with_missing_required_fields
FROM salesforce_customers
WHERE legacy_customer_id IS NULL
   OR TRIM(legacy_customer_id) = ''
   OR full_name IS NULL
   OR TRIM(full_name) = ''
   OR email IS NULL
   OR TRIM(email) = '';


/* 10. Confirm transformation formatting */

SELECT
    COUNT(*) AS invalid_target_email_formats
FROM salesforce_customers
WHERE email NOT REGEXP
    '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$';


SELECT
    COUNT(*) AS invalid_target_phone_formats
FROM salesforce_customers
WHERE phone IS NOT NULL
  AND phone NOT REGEXP '^[0-9]{10}$';


/* 11. Migration-log history */

SELECT
    migration_id,
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
FROM migration_log
ORDER BY migration_id;


/* 12. Final quality gate */

SELECT
    CASE
        WHEN
            (SELECT COUNT(*) FROM legacy_customers) = 10000
            AND
            (
                SELECT COUNT(*)
                FROM staging_customers
            ) = 10000
            AND
            (
                SELECT COUNT(*)
                FROM salesforce_customers
            ) = (
                SELECT COUNT(*)
                FROM staging_customers
                WHERE validation_status = 'Valid'
            )
            AND
            (
                SELECT COUNT(*)
                FROM staging_customers AS sc
                INNER JOIN salesforce_customers AS sf
                    ON sc.legacy_customer_id = sf.legacy_customer_id
                WHERE sc.validation_status = 'Rejected'
            ) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS final_migration_quality_gate;