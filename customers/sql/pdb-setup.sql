CREATE PLUGGABLE DATABASE customers_pdb
    ADMIN USER admin IDENTIFIED BY Oracle21c
    FILE_NAME_CONVERT = (
        '/opt/oracle/oradata/ORCLCDB/pdbseed/',
        '/opt/oracle/oradata/ORCLCDB/customers_pdb/'
    );

SHOW PDBS;

ALTER PLUGGABLE DATABASE customers_pdb OPEN;

SHOW CON_NAME;

ALTER SESSION SET CONTAINER = CDB$ROOT;
ALTER SESSION SET CONTAINER = customers_pdb;
-- Create a new user
CREATE USER customers_service IDENTIFIED BY Oracle21c;

-- Grant basic connection and resource privileges
GRANT CONNECT, RESOURCE TO customers_service;

-- Allow unlimited quota on the SYSTEM tablespace
ALTER USER customers_service QUOTA UNLIMITED ON SYSTEM;

-- Grant necessary permissions for Advanced Queueing
GRANT EXECUTE ON dbms_aqadm TO customers_service;
GRANT EXECUTE ON dbms_aq TO customers_service;
GRANT aq_administrator_role TO customers_service;