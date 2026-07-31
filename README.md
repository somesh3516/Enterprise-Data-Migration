# Enterprise Data Migration & API Integration Platform

## Project Overview

This project simulates an enterprise customer data migration from a legacy CRM system into a Salesforce-like target environment. It demonstrates SQL database design, ETL processing, REST API development, Python automation, data validation, reconciliation, and Power BI reporting.

---

## Technologies

- Python
- MySQL
- Flask
- REST API
- Power BI
- SQL
- Pandas
- Requests

---

## Project Architecture

Legacy CRM CSV

↓

Python Data Generator

↓

MySQL Source Database

↓

Validation & Staging

↓

Salesforce Target

↓

REST API

↓

Power BI Dashboard

---

## Features

- Generated 10,000 realistic customer records
- Automated ETL pipeline
- Data validation
- Duplicate detection
- Data reconciliation
- Migration logging
- REST API
- Batch API loader
- Power BI dashboard
- Executive KPI reporting

---

## REST API Endpoints

GET /health

GET /customers

GET /customers/{legacy_customer_id}

GET /migration-status

POST /customers

---

## Validation Rules

- Email Required
- Phone Required
- Duplicate Email
- Invalid Email Format
- Invalid ZIP Code
- Invalid State

---

## Dashboard

The Power BI dashboard displays:

- Total Source Records
- Valid Records
- Rejected Records
- Target Records
- Migration Success %
- Validation Rule Breakdown
- Validation Status
- Migrated Customers by State
- Validation Exceptions
- Migration Audit Log

---

## Project Structure

Enterprise-Data-Migration/

├── api/

├── data/

├── powerbi/

├── python/

├── reports/

├── screenshots/

├── sql/

├── README.md

└── requirements.txt