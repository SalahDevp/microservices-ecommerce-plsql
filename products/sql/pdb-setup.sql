CREATE PLUGGABLE DATABASE products_pdb
    ADMIN USER admin IDENTIFIED BY Oracle21c
    FILE_NAME_CONVERT = (
        '/opt/oracle/oradata/ORCLCDB/pdbseed/',
        '/opt/oracle/oradata/ORCLCDB/products_pdb/'
    );

SHOW PDBS;

ALTER PLUGGABLE DATABASE products_pdb OPEN;

SHOW CON_NAME;

ALTER SESSION SET CONTAINER = CDB$ROOT;
ALTER SESSION SET CONTAINER = products_pdb;
-- Create a new user
CREATE USER products_service IDENTIFIED BY Oracle21c;

-- Grant basic connection and resource privileges
GRANT CONNECT, RESOURCE TO products_service;

-- Allow unlimited quota on the SYSTEM tablespace
ALTER USER products_service QUOTA UNLIMITED ON SYSTEM;

-- Grant necessary permissions for Advanced Queueing
GRANT EXECUTE ON dbms_aqadm TO products_service;
GRANT EXECUTE ON dbms_aq TO products_service;
GRANT aq_administrator_role TO products_service;