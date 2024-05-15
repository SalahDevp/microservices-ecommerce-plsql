CREATE PLUGGABLE DATABASE orders_pdb
    ADMIN USER admin IDENTIFIED BY Oracle21c
    FILE_NAME_CONVERT = (
        '/opt/oracle/oradata/ORCLCDB/pdbseed/',
        '/opt/oracle/oradata/ORCLCDB/orders_pdb/'
    );

SHOW PDBS;

ALTER PLUGGABLE DATABASE orders_pdb OPEN;

SHOW CON_NAME;

ALTER SESSION SET CONTAINER = CDB$ROOT;
ALTER SESSION SET CONTAINER = orders_pdb;
-- Create a new user
CREATE USER orders_service IDENTIFIED BY Oracle21c;

-- Grant basic connection and resource privileges
GRANT CONNECT, RESOURCE TO orders_service;

-- Allow unlimited quota on the SYSTEM tablespace
ALTER USER orders_service QUOTA UNLIMITED ON SYSTEM;

-- Grant necessary permissions for Advanced Queueing
GRANT EXECUTE ON dbms_aqadm TO orders_service;
GRANT EXECUTE ON dbms_aq TO orders_service;
GRANT aq_administrator_role TO orders_service;