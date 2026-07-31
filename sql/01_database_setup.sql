DROP DATABASE IF EXISTS enterprise_data_migration;

CREATE DATABASE enterprise_data_migration;

USE enterprise_data_migration;


-- Source system table: legacy CRM data
CREATE TABLE legacy_customers (
    legacy_customer_id VARCHAR(20) PRIMARY KEY,
    external_id VARCHAR(36),
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    phone VARCHAR(25),
    birth_date DATE,
    street_address VARCHAR(150),
    city VARCHAR(50),
    state VARCHAR(10),
    zip_code VARCHAR(10),
    customer_status VARCHAR(20),
    created_date DATE
);


-- Staging table: cleaned and validated records
CREATE TABLE staging_customers (
    staging_id INT AUTO_INCREMENT PRIMARY KEY,
    legacy_customer_id VARCHAR(20),
    external_id VARCHAR(36),
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    phone VARCHAR(25),
    birth_date DATE,
    street_address VARCHAR(150),
    city VARCHAR(50),
    state VARCHAR(10),
    zip_code VARCHAR(10),
    customer_status VARCHAR(20),
    created_date DATE,
    validation_status VARCHAR(20),
    validation_message TEXT,
    processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- Target system table: Salesforce simulation
CREATE TABLE salesforce_customers (
    salesforce_id INT AUTO_INCREMENT PRIMARY KEY,
    legacy_customer_id VARCHAR(20),
    external_id VARCHAR(36),
    full_name VARCHAR(120),
    email VARCHAR(100),
    phone VARCHAR(25),
    birth_date DATE,
    mailing_street VARCHAR(150),
    mailing_city VARCHAR(50),
    mailing_state VARCHAR(10),
    mailing_postal_code VARCHAR(10),
    account_status VARCHAR(20),
    source_created_date DATE,
    migrated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_salesforce_legacy_customer (
        legacy_customer_id
    )
);


-- Stores each validation rule result
CREATE TABLE validation_results (
    validation_id INT AUTO_INCREMENT PRIMARY KEY,
    legacy_customer_id VARCHAR(20),
    validation_rule VARCHAR(100),
    validation_result VARCHAR(20),
    validation_message TEXT,
    validation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- Stores migration run totals and status
CREATE TABLE migration_log (
    migration_id INT AUTO_INCREMENT PRIMARY KEY,
    migration_name VARCHAR(100),
    source_table VARCHAR(100),
    target_table VARCHAR(100),
    records_processed INT DEFAULT 0,
    records_loaded INT DEFAULT 0,
    records_failed INT DEFAULT 0,
    status VARCHAR(20),
    started_at DATETIME,
    completed_at DATETIME,
    notes TEXT
);
