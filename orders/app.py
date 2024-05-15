from flask import Flask, jsonify, request
import oracledb
from flask_cors import CORS
from . import config

app = Flask(__name__)
CORS(app)

# Database connection parameters
dsn = oracledb.makedsn(
    config.ORCL_HOST, config.ORCL_PORT, service_name=config.ORCL_SERVICE
)
connection = oracledb.connect(
    user=config.ORCL_USER, password=config.ORCL_PASSWORD, dsn=dsn
)


@app.route("/carts/<int:customer_id>", methods=["GET", "DELETE"])
def carts(customer_id):
    cursor = connection.cursor()
    try:
        if request.method == "GET":

            result_cursor = cursor.callfunc(
                "main_p.get_cart", oracledb.CURSOR, [customer_id]
            )

            products = result_cursor.fetchall()

            columns = [col[0].lower() for col in result_cursor.description]
            products = [dict(zip(columns, row)) for row in products]

            result_cursor.close()
            return jsonify(products)

        elif request.method == "DELETE":
            cursor.callproc("main_p.clear_cart", [customer_id])
            return jsonify({"message": "Cart cleared successfully"}), 200

    except oracledb.DatabaseError as e:
        (error,) = e.args
        return jsonify({"message": "Database error: " + error.message}), 500
    finally:
        cursor.close()


@app.route("/carts/<int:customer_id>/products/<int:product_id>", methods=["PUT"])
def carts_content(customer_id, product_id):
    cursor = connection.cursor()
    data = request.json
    try:
        if not data["delete"]:
            # Add product or add quantity to the product in the cart

            cursor.callproc(
                "main_p.add_product_cart",
                [
                    customer_id,
                    product_id,
                    data["quantity"],
                ],
            )

            return jsonify({"message": "Cart updated successfully"}), 200

        else:
            # Reduce the quantity of the product in the cart, if all quantity is removed then remove the product from the cart
            cursor.callproc(
                "main_p.remove_product_cart",
                [customer_id, product_id, data["quantity"]],
            )
            return jsonify({"message": "Cart updated successfully"}), 200

    except oracledb.DatabaseError as e:
        (error,) = e.args
        return jsonify({"message": "Database error: " + error.message}), 500
    finally:
        cursor.close()


@app.route("/orders", methods=["GET"])
def orders():
    cursor = connection.cursor()
    try:
        result_cursor = cursor.callfunc("main_p.get_orders", oracledb.CURSOR)
        orders = result_cursor.fetchall()

        columns = [col[0].lower() for col in result_cursor.description]
        orders = [dict(zip(columns, row)) for row in orders]

        result_cursor.close()
        return jsonify(orders)

    except oracledb.DatabaseError as e:
        (error,) = e.args
        return jsonify({"message": "Database error: " + error.message}), 500
    finally:
        cursor.close()


@app.route("/orders/<int:customer_id>", methods=["POST"])
def customers_orders(customer_id):
    cursor = connection.cursor()
    try:
        cursor.callproc("main_p.order_cart", [customer_id])
        return jsonify({"message": "Order created successfully"}), 200
    except oracledb.DatabaseError as e:
        (error,) = e.args
        return jsonify({"message": "Database error: " + error.message}), 500
    finally:
        cursor.close()


if __name__ == "__main__":
    app.run(port=5000, debug=True)
