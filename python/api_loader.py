from __future__ import annotations

import time
from getpass import getpass

import mysql.connector
import requests
from mysql.connector import Error


API_URL = "http://127.0.0.1:5000/customers"
BATCH_LIMIT = 100
REQUEST_DELAY_SECONDS = 0.02


def fetch_valid_customers(
    connection: mysql.connector.MySQLConnection,
    limit: int,
) -> list[dict]:
    query = """
        SELECT
            legacy_customer_id,
            CONCAT_WS(' ', first_name, last_name) AS full_name,
            email,
            phone,
            state AS mailing_state
        FROM staging_customers
        WHERE validation_status = 'Valid'
        ORDER BY staging_id
        LIMIT %s;
    """

    cursor = connection.cursor(dictionary=True)
    cursor.execute(query, (limit,))
    customers = cursor.fetchall()
    cursor.close()

    return customers


def send_customer(customer: dict) -> tuple[str, int, str]:
    try:
        response = requests.post(
            API_URL,
            json=customer,
            timeout=10,
        )

        response_data = response.json()
        message = response_data.get("message", "No message returned")

        if response.status_code == 201:
            return "success", response.status_code, message

        if response.status_code == 409:
            return "duplicate", response.status_code, message

        return "failed", response.status_code, message

    except requests.RequestException as error:
        return "failed", 0, str(error)


def main() -> None:
    mysql_user = input("MySQL username [root]: ").strip() or "root"
    mysql_password = getpass("MySQL password: ")

    connection = None

    try:
        connection = mysql.connector.connect(
            host="localhost",
            port=3306,
            user=mysql_user,
            password=mysql_password,
            database="enterprise_data_migration",
        )

        customers = fetch_valid_customers(
            connection=connection,
            limit=BATCH_LIMIT,
        )

        print(f"\nFound {len(customers)} valid customers.")
        print(f"Sending records to {API_URL}\n")

        success_count = 0
        duplicate_count = 0
        failed_count = 0

        for index, customer in enumerate(customers, start=1):
            result, status_code, message = send_customer(customer)

            if result == "success":
                success_count += 1
            elif result == "duplicate":
                duplicate_count += 1
            else:
                failed_count += 1

            print(
                f"[{index}/{len(customers)}] "
                f"{customer['legacy_customer_id']} | "
                f"{result.upper()} | "
                f"HTTP {status_code} | "
                f"{message}"
            )

            time.sleep(REQUEST_DELAY_SECONDS)

        print("\nAPI load complete")
        print(f"Successful: {success_count}")
        print(f"Duplicates: {duplicate_count}")
        print(f"Failed: {failed_count}")
        print(f"Processed: {len(customers)}")

    except Error as error:
        print(f"MySQL error: {error}")

    except Exception as error:
        print(f"Unexpected error: {error}")

    finally:
        if connection is not None and connection.is_connected():
            connection.close()


if __name__ == "__main__":
    main()