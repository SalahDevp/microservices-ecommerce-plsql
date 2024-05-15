import os

PRODUCTS_SERVICE_URL = os.getenv("PRODUCTS_SERVICE_URL", "http://localhost:5000")
ORDERS_SERVICE_URL = os.getenv("ORDERS_SERVICE_URL", "http://localhost:5001")
CUSTOMERS_SERVICE_URL = os.getenv("CUSTOMERS_SERVICE_URL", "http://localhost:5002")
