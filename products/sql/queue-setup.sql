CREATE OR REPLACE TYPE messages_t AS OBJECT (
  event_type VARCHAR(255) ,
  payload CLOB
);

BEGIN
  DBMS_AQADM.CREATE_QUEUE_TABLE(
    queue_table        => 'products_queue_table',
    queue_payload_type => 'messages_t',
    multiple_consumers => true
  );

  DBMS_AQADM.CREATE_QUEUE(
    queue_name  => 'products_queue',
    queue_table => 'products_queue_table'
  );

  DBMS_AQADM.START_QUEUE(queue_name => 'products_queue');
END;