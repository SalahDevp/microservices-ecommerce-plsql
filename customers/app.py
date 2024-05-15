from flask import Flask, jsonify, request
import oracledb
from flask_cors import CORS
from . import config

app = Flask(__name__)
CORS(app)

dsn = oracledb.makedsn(
    config.ORCL_HOST, config.ORCL_PORT, service_name=config.ORCL_SERVICE
)
connection = oracledb.connect(
    user=config.ORCL_USER, password=config.ORCL_PASSWORD, dsn=dsn
)


@app.route("/customers", methods=["GET", "POST"])
def customers():
    cursor = connection.cursor()
    try:
        if request.method == "GET":

            result_cursor = cursor.callfunc("main_p.get_users", oracledb.CURSOR)

            customers = result_cursor.fetchall()

            columns = [col[0].lower() for col in result_cursor.description]
            customers = [dict(zip(columns, row)) for row in customers]

            result_cursor.close()
            return jsonify(customers)

        elif request.method == "POST":
            data = request.json

            cursor.callproc(
                "main_p.add_user",
                [
                    data["name"],
                    data["phone"],
                    data["address"],
                    data["balance"],
                ],
            )

            return jsonify({"message": "Customer added successfully"}), 200

    except oracledb.DatabaseError as e:
        (error,) = e.args
        return jsonify({"message": "Database error: " + error.message}), 500
    finally:
        cursor.close()


@app.route("/customers/<int:id>", methods=["PUT", "DELETE"])
def customers_details(id):
    cursor = connection.cursor()
    try:
        if request.method == "PUT":
            data = request.json

            balance_change = data["balance_change"]

            if balance_change < 0:
                cursor.callproc("main_p.subtract_balance", [id, abs(balance_change)])
            else:
                cursor.callproc(
                    "main_p.add_balance",
                    [id, balance_change],
                )

            return jsonify({"message": "Customer updated successfully"}), 200

        elif request.method == "DELETE":
            cursor.callproc("main_p.delete_user", [id])
            return jsonify({"message": "Customer deleted successfully"}), 200

    except oracledb.DatabaseError as e:
        (error,) = e.args
        return jsonify({"message": "Database error: " + error.message}), 500
    finally:
        cursor.close()


if __name__ == "__main__":
    app.run(debug=True)
