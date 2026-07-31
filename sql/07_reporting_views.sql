/*
===============================================================================
Enterprise Data Migration
07 - Reporting Views
===============================================================================

Purpose:
    Creates reusable reporting views for migration status, validation results,
    reconciliation metrics, and exception reporting.
===============================================================================
*/

USE enterprise_data_migration;


/* ---------------------------------------------------------------------------
   1. Migration summary
--------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW vw_migration_summary AS
SELECT
    ml.migration_id,
    ml.migration_name,
    ml.source_table,
    ml.target_table,
    ml.records_processed,
    ml.records_loaded,
    ml.records_failed,
    ROUND(
        (
            ml.records_loaded /
            NULLIF(ml.records_processed, 0)
        ) * 100,
        2
    ) AS success_rate_percent,
    ml.status,
    ml.started_at,
    ml.completed_at,
    TIMESTAMPDIFF(
        SECOND,
        ml.started_at,
        ml.completed_at
    ) AS execution_time_seconds,
    ml.notes
FROM migration_log AS ml;


/* ---------------------------------------------------------------------------
   2. Data quality scorecard
--------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW vw_data_quality_scorecard AS
SELECT
    'Email Required' AS validation_rule,
    COUNT(*) AS total_records,
    SUM(
        email IS NOT NULL
        AND TRIM(email) <> ''
    ) AS passed_records,
    SUM(
        email IS NULL
        OR TRIM(email) = ''
    ) AS failed_records,
    ROUND(
        (
            SUM(
                email IS NOT NULL
                AND TRIM(email) <> ''
            ) / COUNT(*)
        ) * 100,
        2
    ) AS pass_rate_percent
FROM legacy_customers

UNION ALL

SELECT
    'Email Format',
    COUNT(*),
    SUM(
        email IS NOT NULL
        AND TRIM(email) <> ''
        AND email REGEXP
            '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'
    ),
    SUM(
        email IS NOT NULL
        AND TRIM(email) <> ''
        AND email NOT REGEXP
            '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'
    ),
    ROUND(
        (
            SUM(
                email IS NOT NULL
                AND TRIM(email) <> ''
                AND email REGEXP
                    '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'
            ) / COUNT(*)
        ) * 100,
        2
    )
FROM legacy_customers

UNION ALL

SELECT
    'Phone Required',
    COUNT(*),
    SUM(
        phone IS NOT NULL
        AND TRIM(phone) <> ''
    ),
    SUM(
        phone IS NULL
        OR TRIM(phone) = ''
    ),
    ROUND(
        (
            SUM(
                phone IS NOT NULL
                AND TRIM(phone) <> ''
            ) / COUNT(*)
        ) * 100,
        2
    )
FROM legacy_customers

UNION ALL

SELECT
    'State Validation',
    COUNT(*),
    SUM(
        state IN ('VA', 'NC', 'GA', 'MD', 'PA')
    ),
    SUM(
        state NOT IN ('VA', 'NC', 'GA', 'MD', 'PA')
    ),
    ROUND(
        (
            SUM(
                state IN ('VA', 'NC', 'GA', 'MD', 'PA')
            ) / COUNT(*)
        ) * 100,
        2
    )
FROM legacy_customers

UNION ALL

SELECT
    'ZIP Code Format',
    COUNT(*),
    SUM(
        zip_code REGEXP '^[0-9]{5}$'
    ),
    SUM(
        zip_code NOT REGEXP '^[0-9]{5}$'
    ),
    ROUND(
        (
            SUM(
                zip_code REGEXP '^[0-9]{5}$'
            ) / COUNT(*)
        ) * 100,
        2
    )
FROM legacy_customers;


/* ---------------------------------------------------------------------------
   3. Validation exception detail
--------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW vw_validation_exceptions AS
SELECT
    vr.validation_id,
    vr.legacy_customer_id,
    lc.first_name,
    lc.last_name,
    lc.email,
    lc.phone,
    lc.city,
    lc.state,
    lc.zip_code,
    vr.validation_rule,
    vr.validation_result,
    vr.validation_message,
    vr.validation_date
FROM validation_results AS vr
INNER JOIN legacy_customers AS lc
    ON vr.legacy_customer_id = lc.legacy_customer_id;


/* ---------------------------------------------------------------------------
   4. Staging status summary
--------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW vw_staging_status_summary AS
SELECT
    validation_status,
    COUNT(*) AS record_count,
    ROUND(
        (
            COUNT(*) /
            NULLIF(
                (SELECT COUNT(*) FROM staging_customers),
                0
            )
        ) * 100,
        2
    ) AS record_percentage
FROM staging_customers
GROUP BY validation_status;


/* ---------------------------------------------------------------------------
   5. Reconciliation summary
--------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW vw_reconciliation_summary AS
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
             staging.valid_staging_records +
             staging.rejected_staging_records
         AND staging.total_staging_records =
             source.total_source_records
         AND target.total_target_records =
             staging.valid_staging_records
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
            SUM(validation_status = 'Valid')
                AS valid_staging_records,
            SUM(validation_status = 'Rejected')
                AS rejected_staging_records
        FROM staging_customers
    ) AS staging
CROSS JOIN
    (
        SELECT COUNT(*) AS total_target_records
        FROM salesforce_customers
    ) AS target;