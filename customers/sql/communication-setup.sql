-- create link (use sys user)
CREATE PUBLIC DATABASE LINK link_to_orders
  CONNECT TO orders_service IDENTIFIED BY Oracle21c
  USING '(DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = localhost)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = orders_pdb)
    )
  )';
  
-- propagation
BEGIN
  dbms_aqadm.schedule_propagation(
    queue_name     => 'customers_queue',
    destination    => 'LINK_TO_ORDERS',
    start_time     => SYSTIMESTAMP,
    duration       => NULL,
    latency        => 0,
    destination_queue => 'orders_service.orders_queue'
  );
EXCEPTION
  WHEN OTHERS THEN
    dbms_output.put_line('Error while scheduling propagation: ' || sqlerrm);
END;
--subscribe to queue
DECLARE
    subscriber sys.aq$_agent;
BEGIN
    subscriber := sys.aq$_agent('orders_service', 'orders_service.orders_queue@LINK_TO_ORDERS', NULL);
    dbms_aqadm.add_subscriber(queue_name => 'customers_queue', subscriber => subscriber, queue_to_queue => true);
    
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('error while adding subscribers: ' || sqlerrm);
END;


--Test setup
SELECT
    QUEUE_NAME,        
    CONSUMER_NAME AS C_NAME,
    TRANSFORMATION,  
    ADDRESS,          
    QUEUE_TO_QUEUE
FROM USER_QUEUE_SUBSCRIBERS;

SELECT
  qname,
  destination,
  message_delivery_mode,
  job_name
FROM
  user_queue_schedules
where destination like '%LINK_TO_ORDERS%';