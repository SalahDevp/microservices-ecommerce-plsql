### Step 1: Create Pluggable Databases (PDBs)

1. **Locate the Creation Scripts:** In the parent folder containing the source code, navigate to the `sql` folder within each service folder:

   - `products` for `products_pdb`
   - `orders` for `orders_pdb`
   - `customers` for `customers_pdb`

2. **Run the Scripts:** Execute the `pdb-setup.sql` file located in each service's `sql` folder to create the respective pluggable databases:

   - For the Products Database: Run the script in the `products` folder.
   - For the Orders Database: Run the script in the `orders` folder.
   - For the Customers Database: Run the script in the `customers` folder.

### Step 2: Import Database Content

1. **Locate the Backup Files:**
   In the `backup` folder within the parent directory, find the `.dmp` files for each pluggable database:

   - `products_pdb.dmp` for the Products database
   - `orders_pdb.dmp` for the Orders database
   - `customers_pdb.dmp` for the Customers database

2. **Import Data:**
   Use the `impdp` command to import data from each `.dmp` file into the corresponding pluggable database. Here’s an example command for importing data into the `products_pdb`:
   ```
   impdp username/password@products_pdb directory=backup_dir dumpfile=products_pdb.dmp logfile=import_products.log
   ```
   Replace `username/password` with your Oracle credentials and adjust the directory path if necessary. Repeat the process for `orders_pdb` and `customers_pdb` using their respective dump files.

### Step 3: Start the Application with Docker Compose

1. **Prepare the Environment:**
   Open a terminal in the directory containing the `docker-compose.yml` file.

2. **Configure Database Connection:**
   Ensure the database settings in the `db.env` file are correct. By default, the database should be running on `localhost` port `1521`. Modify these settings in the `db.env` file if your database configuration differs.

3. **Launch the Application:**
   Execute the following command to build and start all the services defined in your Docker Compose configuration:
   ```
   docker compose up --build
   ```
   This command builds the necessary Docker images and starts the containers.

### Step 4: Access the Application

1. **Access the Frontend:**
   Open a web browser and navigate to `http://localhost:3000` to view the frontend of the e-commerce application. This interface allows interaction with the various CRUD features .

2. **Access the API Directly:**
   For direct API interactions, such as sending HTTP requests or testing endpoints, use the address `http://localhost:8000`.
