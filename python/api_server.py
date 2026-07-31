from __future__ import annotations

from flask import Flask, jsonify, request

app = Flask(__name__)

customers: list[dict] = []
next_salesforce_id = 1


@app.get("/health")
def health_check():
    return jsonify(
        {
            "status": "healthy",
            "service": "salesforce-customer-api-simulation",
        }
    )


@app.get("/customers")
def get_customers():
    return jsonify(
        {
            "count": len(customers),
            "customers": customers,
        }
    )


@app.get("/customers/<legacy_customer_id>")
def get_customer(legacy_customer_id: str):
    customer = next(
        (
            item
            for item in customers
            if item["legacy_customer_id"] == legacy_customer_id
        ),
        None,
    )

    if customer is None:
        return (
            jsonify(
                {
                    "status": "error",
                    "message": "Customer not found",
                }
            ),
            404,
        )

    return jsonify(customer)


@app.post("/customers")
def create_customer():
    global next_salesforce_id

    payload = request.get_json(silent=True)

    if not payload:
        return (
            jsonify(
                {
                    "status": "error",
                    "message": "A JSON request body is required",
                }
            ),
            400,
        )

    required_fields = [
        "legacy_customer_id",
        "full_name",
        "email",
        "phone",
        "mailing_state",
    ]

    missing_fields = [
        field
        for field in required_fields
        if not payload.get(field)
    ]

    if missing_fields:
        return (
            jsonify(
                {
                    "status": "error",
                    "message": "Missing required fields",
                    "missing_fields": missing_fields,
                }
            ),
            400,
        )

    duplicate = next(
        (
            item
            for item in customers
            if item["legacy_customer_id"]
            == payload["legacy_customer_id"]
        ),
        None,
    )

    if duplicate:
        return (
            jsonify(
                {
                    "status": "error",
                    "message": "Customer already exists",
                    "legacy_customer_id": payload["legacy_customer_id"],
                }
            ),
            409,
        )

    customer = {
        "salesforce_id": next_salesforce_id,
        "legacy_customer_id": payload["legacy_customer_id"],
        "full_name": payload["full_name"],
        "email": payload["email"],
        "phone": payload["phone"],
        "mailing_state": payload["mailing_state"],
        "status": "created",
    }

    customers.append(customer)
    next_salesforce_id += 1

    return (
        jsonify(
            {
                "status": "success",
                "message": "Customer created",
                "customer": customer,
            }
        ),
        201,
    )


@app.get("/migration-status")
def migration_status():
    return jsonify(
        {
            "api_records_loaded": len(customers),
            "status": "Completed" if customers else "Not Started",
        }
    )


if __name__ == "__main__":
    app.run(
        host="127.0.0.1",
        port=5000,
        debug=True,
    )