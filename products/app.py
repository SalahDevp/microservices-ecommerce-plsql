from flask import Flask, jsonify, request
import oracledb

app = Flask(__name__)

# Database connection parameters
dsn = oracledb.makedsn("localhost", "1521", service_name="products_pdb")
connection = oracledb.connect(user="products_service", password="Oracle21c", dsn=dsn)


@app.route("/products", methods=["GET", "POST"])
def products():
    cursor = connection.cursor()
    try:
        if request.method == "GET":

            result_cursor = cursor.callfunc("main_p.get_all_products", oracledb.CURSOR)

            products = result_cursor.fetchall()

            columns = [col[0] for col in result_cursor.description]
            products = [dict(zip(columns, row)) for row in products]

            result_cursor.close()
            return jsonify(products)

        elif request.method == "POST":
            data = request.json

            cursor.callproc(
                "main_p.insert_product",
                [
                    data["product_code"],
                    data["name"],
                    data["description"],
                    data["category_id"],
                    data["price"],
                    data["stock"],
                ],
            )

            return jsonify({"message": "Product added successfully"}), 200

    except oracledb.DatabaseError as e:
        (error,) = e.args
        return jsonify({"message": "Database error: " + error.message}), 500
    finally:
        cursor.close()


@app.route("/products/<int:id>", methods=["PUT", "DELETE"])
def product_details(id):
    cursor = connection.cursor()
    try:
        if request.method == "PUT":
            data = request.json

            product_code = data.get("product_code")
            name = data.get("name", None)
            description = data.get("description", None)
            category_id = data.get("category_id", None)
            price = data.get("price", None)
            stock = data.get("stock", None)

            # Call the stored procedure
            cursor.callproc(
                "main_p.edit_product",
                [id, product_code, name, description, category_id, price, stock],
            )
            return jsonify({"message": "Product updated successfully"}), 200

        elif request.method == "DELETE":
            cursor.callproc("main_p.delete_product", [id])
            return jsonify({"message": "Product deleted successfully"}), 200

    except oracledb.DatabaseError as e:
        (error,) = e.args
        return jsonify({"message": "Database error: " + error.message}), 500
    finally:
        cursor.close()


if __name__ == "__main__":
    app.run(debug=False)
