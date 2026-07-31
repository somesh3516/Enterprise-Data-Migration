from __future__ import annotations

from getpass import getpass
from pathlib import Path

import mysql.connector
import pandas as pd
from mysql.connector import Error


OUTPUT_FOLDER = Path("validation")


def export_query(
    connection: mysql.connector.MySQLConnection,
    query: str,
    output_file: Path,
    sheet_name: str,
) -> None:
    """Run a SQL query and export the results to an Excel workbook."""

    dataframe = pd.read_sql(query, connection)

    with pd.ExcelWriter(
        output_file,
        engine="openpyxl",
    ) as writer:
        dataframe.to_excel(
            writer,
            sheet_name=sheet_name,
            index=False,
        )

    print(f"Created: {output_file}")


def main() -> None:
    OUTPUT_FOLDER.mkdir(parents=True, exist_ok=True)

    mysql_user = input("MySQL username [root]: ").strip() or "root"
    mysql_password = getpass("MySQL password: ")

    try:
        connection = mysql.connector.connect(
            host="localhost",
            port=3306,
            user=mysql_user,
            password=mysql_password,
            database="enterprise_data_migration",
        )

        if not connection.is_connected():
            raise ConnectionError("Could not connect to MySQL.")

        export_query(
            connection,
            """
            SELECT *
            FROM vw_validation_exceptions
            ORDER BY validation_rule, legacy_customer_id;
            """,
            OUTPUT_FOLDER / "validation_report.xlsx",
            "Validation Exceptions",
        )

        export_query(
            connection,
            """
            SELECT *
            FROM vw_reconciliation_summary;
            """,
            OUTPUT_FOLDER / "reconciliation_report.xlsx",
            "Reconciliation",
        )

        export_query(
            connection,
            """
            SELECT *
            FROM vw_data_quality_scorecard
            ORDER BY pass_rate_percent;
            """,
            OUTPUT_FOLDER / "data_quality_scorecard.xlsx",
            "Data Quality Scorecard",
        )

        export_query(
            connection,
            """
            SELECT *
            FROM vw_migration_summary
            ORDER BY migration_id;
            """,
            OUTPUT_FOLDER / "migration_history.xlsx",
            "Migration History",
        )

        print("\nAll migration reports were generated successfully.")

    except Error as error:
        print(f"MySQL error: {error}")

    except Exception as error:
        print(f"Unexpected error: {error}")

    finally:
        if "connection" in locals() and connection.is_connected():
            connection.close()


if __name__ == "__main__":
    main()