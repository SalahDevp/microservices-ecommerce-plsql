import os

ORCL_HOST = os.getenv("ORCL_HOST", "localhost")
ORCL_PORT = os.getenv("ORCL_PORT", "1521")
ORCL_SERVICE = os.getenv("ORCL_SERVICE", "customers_pdb")
ORCL_USER = os.getenv("ORCL_USER", "customers_service")
ORCL_PASSWORD = os.getenv("ORCL_PASSWORD", "Oracle21c")
