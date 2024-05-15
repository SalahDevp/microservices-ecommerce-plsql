# microservices-ecommerce-plsql

## AQ Setup Guide
### Creating a Pluggable Database (PDB)

This section guides you through creating a Pluggable Database named `orders_pdb`. Follow these steps to set up the database, and repeat the process for another PDB, such as `products_pdb`, by substituting the relevant names and paths.

1. **Create `orders_pdb`**:
   Use the following SQL script to create the `orders_pdb` with an admin user. This script specifies how the files should be converted from the seed database directory to the new pluggable database directory.

   ```sql
   CREATE PLUGGABLE DATABASE orders_pdb
       ADMIN USER admin IDENTIFIED BY Oracle21c
       FILE_NAME_CONVERT = (
           '/opt/oracle/oradata/ORCLCDB/pdbseed/',
           '/opt/oracle/oradata/ORCLCDB/orders_pdb/'
       );
   ```

2. **View Created PDBs**:
   To verify the creation, list all available PDBs using the command below:

   ```sql
   SHOW PDBS;
   ```

3. **Open `orders_pdb`**:
   Open the newly created `orders_pdb` for use:

   ```sql
   ALTER PLUGGABLE DATABASE orders_pdb OPEN;
   ```

4. **Check Current PDB**:
   To check which Pluggable Database your session is currently connected to, execute:

   ```sql
   SHOW CON_NAME;
   ```

**Note**: Follow the same instructions to create another PDB, like `products_pdb`. Ensure to adjust the database names and paths as needed to match your requirements.

### Creating a User in a Pluggable Database (PDB)

This section outlines the steps to create a user within a Pluggable Database. We'll use `orders_pdb` as an example. Follow the same steps for other PDBs, like `products_pdb`, adjusting user names and database names as required.

1. **Connect to PDB as Admin**:
   Using SQL Developer, connect to the database as the PDB administrator. Use the username `admin` and password `Oracle21c`, specifying the PDB name (`orders_pdb`) in the service name field of your connection settings.

2. **Create User in `orders_pdb`**:
   Run the following SQL script to create a user named `orders_service` in the `orders_pdb`. This script sets up the user with necessary privileges and unlimited quota on the SYSTEM tablespace.

   ```sql
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
   ```

3. **Repeat for Other PDBs**:
   To create a user in another PDB (e.g., `products_pdb`), repeat the steps above. Make sure to connect to the correct PDB and adjust the user creation script to reflect the different user and database names, if necessary.

**Note**: Ensure that each user created has appropriate permissions and resource limits as required by their role and the applications they support.

### Setting Up Queues and Linking Them Between PDBs

This section details setting up message queues in `orders_pdb` and creating a link to `products_pdb` for message propagation.

#### On the Sender Side (`orders_pdb`)

1. **Create Message Type**:
   Define a custom type for the message payload. This type will structure the messages that are sent through the queue.

   ```sql
   CREATE OR REPLACE TYPE messages_t AS OBJECT (
     message VARCHAR2(100 CHAR)
   );
   ```

2. **Create Packages for Message Handling**:
   Define a package `test_p` that includes a procedure to enqueue messages into the queue.

   ```sql
   CREATE OR REPLACE PACKAGE test_p AS
     PROCEDURE send_message (
       queue_name        IN VARCHAR2,
       message_content   IN VARCHAR2
     );
   END;

   CREATE OR REPLACE PACKAGE BODY test_p AS
     PROCEDURE send_message (
       queue_name        IN VARCHAR2,
       message_content   IN VARCHAR2
     ) IS
       enq_msgid RAW(16);
       eopt      DBMS_AQ.ENQUEUE_OPTIONS_T;
       mprop     DBMS_AQ.MESSAGE_PROPERTIES_T;
     BEGIN
       DBMS_AQ.ENQUEUE(
         queue_name        => queue_name,
         enqueue_options   => eopt,
         message_properties=> mprop,
         payload           => messages_t(message_content),
         msgid             => enq_msgid
       );
       COMMIT;
     END send_message;
   END;
   ```

3. **Create and Start the Queue**:
   Establish the queue table and the queue itself, ensuring it supports multiple consumers.

   ```sql
   BEGIN
     DBMS_AQADM.CREATE_QUEUE_TABLE(
       queue_table        => 'order_queue_table',
       queue_payload_type => 'messages_t',
       multiple_consumers => true
     );

     DBMS_AQADM.CREATE_QUEUE(
       queue_name  => 'order_queue',
       queue_table => 'order_queue_table'
     );

     DBMS_AQADM.START_QUEUE(queue_name => 'order_queue');
   END;
   ```

4. **Create a Database Link**:
   Set up a public database link from `orders_pdb` to `products_pdb` to enable communication between the two databases.

   ```sql
   CREATE PUBLIC DATABASE LINK link_to_products
     CONNECT TO products_service IDENTIFIED BY Oracle21c
     USING '(DESCRIPTION =
       (ADDRESS = (PROTOCOL = TCP)(HOST = localhost)(PORT = 1521))
       (CONNECT_DATA =
         (SERVER = DEDICATED)
         (SERVICE_NAME = products_pdb)
       )
     )';
   ```

   Validate the link and check connectivity:

   ```sql
   SELECT DB_LINK, USERNAME, HOST, CREATED FROM ALL_DB_LINKS WHERE DB_LINK = 'LINK_TO_PRODUCTS';
   SELECT COUNT(*) FROM PRODUCTS_SERVICE.PRODUCT_QUEUE_TABLE@LINK_TO_PRODUCTS;
   ```

5. **Set Up Propagation**:
   Schedule message propagation from `orders_pdb` to `products_pdb` through the established link, starting immediately and indefinitely without delay.

   ```sql
   BEGIN
     dbms_aqadm.schedule_propagation(
       queue_name     => 'order_queue',
       destination    => 'LINK_TO_PRODUCTS',
       start_time     => SYSTIMESTAMP,
       duration       => NULL,
       latency        => 0
     );
   EXCEPTION
     WHEN OTHERS THEN
       dbms_output.put_line('Error while scheduling propagation: ' || sqlerrm);
   END;
   ```

   Check the propagation setup:

   ```sql
   SELECT
     qname,
     destination,
     message_delivery_mode,
     job_name
   FROM
     user_queue_schedules
   where destination like '%LINK_TO_PRODUCTS%';
   ```

This setup on `orders_pdb` will ensure messages are correctly created, managed, and propagated to `products_pdb`. Repeat similar steps for any other PDBs as needed, adjusting database links and queue names accordingly.

### Setting Up the Receiver Side (`products_pdb`)

This section describes the configuration necessary for setting up the receiving part of the message queue system in `products_pdb`.

1. **Create Message Type**:
   Define a custom type for the message payload. This type structures the messages that are received through the queue.

   ```sql
   CREATE OR REPLACE TYPE messages_t AS OBJECT (
     message VARCHAR2(100 CHAR)
   );
   ```

2. **Create a Table to Store Received Messages**:
   Establish a table to log received messages for testing and verification purposes.

   ```sql
   CREATE TABLE messages(
       id INT generated as identity,
       message VARCHAR2(100 CHAR),
       PRIMARY KEY (id)
   );
   ```

3. **Create and Start the Queue**:
   Setup the queue table and the queue itself, ensuring it supports multiple consumers.

   ```sql
   BEGIN
     DBMS_AQADM.CREATE_QUEUE_TABLE(
       queue_table        => 'product_queue_table',
       queue_payload_type => 'messages_t',
       multiple_consumers => TRUE
     );

     DBMS_AQADM.CREATE_QUEUE(
       queue_name  => 'product_queue',
       queue_table => 'product_queue_table'
     );

     DBMS_AQADM.START_QUEUE(queue_name => 'product_queue');
   END;
   ```



This setup ensures that `products_pdb` is ready to receive messages from `orders_pdb` through the configured message queue. It includes the creation of a storage table for incoming messages, which can be used to verify that messages are being properly received and processed.

### Adding a Subscriber on the Sender Side (`orders_pdb`)

This section guides you on how to add a subscriber to the `order_queue` in `orders_pdb`, enabling message forwarding to `products_pdb`.

1. **Add Subscribers**:
   Define a subscriber for the queue. In this example, `products_service` is added as a subscriber to the `order_queue`. The subscriber's address specifies the queue in `products_pdb` through a database link.

   ```sql
   DECLARE
       subscriber sys.aq$_agent;
   BEGIN
       subscriber := sys.aq$_agent('products_service', 'products_service.product_queue@LINK_TO_PRODUCTS', NULL);
       dbms_aqadm.add_subscriber(queue_name => 'order_queue', subscriber => subscriber);
       
   EXCEPTION
       WHEN OTHERS THEN
           dbms_output.put_line('error while adding subscribers: ' || sqlerrm);
   END;
   ```

2. **Test the Subscriber Configuration**:
   Verify the subscription details by querying the subscriber list for `order_queue`. This helps confirm that the subscription was successfully added and provides details about the queue-to-queue configuration.

   ```sql
   SELECT
       QUEUE_NAME,        
       CONSUMER_NAME AS C_NAME,
       TRANSFORMATION,  
       ADDRESS,          
       QUEUE_TO_QUEUE
   FROM USER_QUEUE_SUBSCRIBERS;
   ```

This setup completes the subscription process, linking `orders_pdb` and `products_pdb`. Messages enqueued in `order_queue` will now be directed to the subscriber's queue based on the configurations provided. This test query ensures that the setup is correct and that the subscriber is ready to receive messages as intended.

### Testing Message Sending and Receiving Between `orders_pdb` and `products_pdb`

This section describes the process to send a test message from `orders_pdb` and then receive it on `products_pdb`, ensuring the entire configuration is functioning as intended.

#### Send a Test Message

1. **Send a Message**:
   Use the `test_p` package's `send_message` procedure to enqueue a message in `order_queue`.

   ```sql
   BEGIN
       test_p.send_message(
           queue_name => 'order_queue',
           message_content => 'hello'
       );
   END;
   ```

#### Verify Message Transformation (Optional)

Check if any transformations are set up on the queues:

```sql
SELECT
    transformation_id as trn_id,
    name,
    from_type,
    to_type
FROM
    user_transformations;
```

#### Receive the Test Message on `products_pdb`

1. **Set Server Output On**:
   Ensure that the server output is enabled in your SQL client to view the results from DBMS_OUTPUT.

   ```sql
   SET SERVEROUTPUT ON;
   ```

2. **Dequeue the Message**:
   Execute a PL/SQL block to dequeue the message from `product_queue`, specifying the consumer name as `products_service`.

   ```sql
   DECLARE
       dequeue_options      dbms_aq.dequeue_options_t;
       message_properties   dbms_aq.message_properties_t;
       message_handle       RAW(16);
       message              messages_t;
       no_messages EXCEPTION;
       end_of_group EXCEPTION;
       PRAGMA exception_init ( no_messages, -25228 );
       PRAGMA exception_init ( end_of_group, -25235 );
   BEGIN
       dequeue_options.wait := dbms_aq.no_wait;
       dequeue_options.navigation := dbms_aq.first_message;
       dequeue_options.consumer_name := 'products_service';
       LOOP 
       BEGIN
           dbms_aq.dequeue(
               queue_name => 'product_queue', 
               dequeue_options => dequeue_options, 
               message_properties => message_properties,
               payload => message, 
               msgid => message_handle
           );
           dbms_output.put_line('message:' || message.message);
           dequeue_options.navigation := dbms_aq.next_message;
       EXCEPTION
           WHEN end_of_group THEN
               dbms_output.put_line('Finished '); 
               COMMIT;
               dequeue_options.navigation := dbms_aq.next_transaction;
       END;   
       END LOOP;
   EXCEPTION
       WHEN no_messages THEN
           dbms_output.put_line('No more messages');
   END;
   ```

This script sends a message, "hello", from `orders_pdb` and attempts to receive it in `products_pdb`. If everything is set up correctly, you should see the message output on your SQL client, confirming the successful setup of your database links, queues, and subscriber configuration.
