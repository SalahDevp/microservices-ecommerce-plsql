from flask import Flask, request, jsonify
import requests
from . import config
from flask_cors import CORS
from .proxy import redirect

app = Flask(__name__)
CORS(app)

all_methods = ["GET", "POST", "PUT", "DELETE", "PATCH"]


@app.route("/carts", methods=all_methods)
@app.route("/orders", methods=all_methods)
def orders_proxy():
    response = redirect(request, config.ORDERS_SERVICE_URL)
    return (response.content, response.status_code, response.headers.items())


@app.route("/products", methods=all_methods)
def products_proxy():
    response = redirect(request, config.PRODUCTS_SERVICE_URL)
    return (response.content, response.status_code, response.headers.items())


@app.route("/customers", methods=all_methods)
def customers_proxy():
    response = redirect(request, config.CUSTOMERS_SERVICE_URL)
    return (response.content, response.status_code, response.headers.items())


if __name__ == "__main__":
    app.run(port=5000)
