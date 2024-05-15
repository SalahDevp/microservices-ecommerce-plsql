create or replace PACKAGE aq_p AS
  PROCEDURE publish_event(event_name VARCHAR2, payload CLOB);
  FUNCTION wait_for_available_stock(p_order_id IN NUMBER) RETURN messages_t;
  FUNCTION wait_for_available_balance(p_order_id IN NUMBER) RETURN messages_t;
END aq_p;

create or replace PACKAGE BODY aq_p AS
  PROCEDURE publish_event(event_name VARCHAR2, payload CLOB) IS
    enqueue_options DBMS_AQ.enqueue_options_t;
    message_properties DBMS_AQ.message_properties_t;
    message_handle RAW(16);
    message messages_t;
  BEGIN
    message := messages_t(event_name, payload);

    DBMS_AQ.ENQUEUE(
      queue_name         => 'orders_queue',
      enqueue_options    => enqueue_options,
      message_properties => message_properties,
      payload            => message,
      msgid              => message_handle
    );

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Enqueue failed: ' || SQLERRM);
      ROLLBACK;
  END publish_event;

  FUNCTION wait_for_available_stock(p_order_id IN NUMBER) RETURN messages_t IS
    dequeue_options DBMS_AQ.dequeue_options_t;
    message_properties DBMS_AQ.message_properties_t;
    message_handle RAW(16);
    message messages_t;
    v_success BOOLEAN := FALSE; 
    BEGIN
        dequeue_options.wait := 10;  -- Wait for 10 seconds
        dequeue_options.navigation := DBMS_AQ.FIRST_MESSAGE;
        dequeue_options.visibility := DBMS_AQ.IMMEDIATE;
        dequeue_options.consumer_name := 'orders_service'; 

        LOOP
            BEGIN
                DBMS_AQ.DEQUEUE(
                    queue_name         => 'orders_queue',
                    dequeue_options    => dequeue_options,
                    message_properties => message_properties,
                    payload            => message,
                    msgid              => message_handle
                );

                EXIT WHEN message.event_type = 'stock_available' AND TO_NUMBER(json_value(message.payload, '$.order_id')) = p_order_id; 
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    EXIT;  -- Exit loop if no message is found within the timeout
                WHEN OTHERS THEN
                    DBMS_OUTPUT.PUT_LINE('Error during dequeue: ' || SQLERRM);
                    EXIT;
            END;
        END LOOP;

        

        COMMIT;  -- Commit to confirm dequeue
        RETURN message;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Unhandled exception: ' || SQLERRM);
            ROLLBACK;
            RETURN messages_t('stock_available', json_object('success' VALUE false));
    END wait_for_available_stock;

    FUNCTION wait_for_available_balance(p_order_id IN NUMBER) RETURN messages_t IS
    dequeue_options DBMS_AQ.dequeue_options_t;
    message_properties DBMS_AQ.message_properties_t;
    message_handle RAW(16);
    message messages_t;
    v_success BOOLEAN := FALSE; 
    BEGIN
        dequeue_options.wait := 10;  -- Wait for 10 seconds
        dequeue_options.navigation := DBMS_AQ.FIRST_MESSAGE;
        dequeue_options.visibility := DBMS_AQ.IMMEDIATE;
        dequeue_options.consumer_name := 'orders_service'; 

        LOOP
            BEGIN
                DBMS_AQ.DEQUEUE(
                    queue_name         => 'orders_queue',
                    dequeue_options    => dequeue_options,
                    message_properties => message_properties,
                    payload            => message,
                    msgid              => message_handle
                );

                EXIT WHEN message.event_type = 'balance_available' AND TO_NUMBER(json_value(message.payload, '$.order_id')) = p_order_id; 
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    EXIT;  -- Exit loop if no message is found within the timeout
                WHEN OTHERS THEN
                    DBMS_OUTPUT.PUT_LINE('Error during dequeue: ' || SQLERRM);
                    EXIT;
            END;
        END LOOP;

        

        COMMIT;  -- Commit to confirm dequeue
        RETURN message;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Unhandled exception: ' || SQLERRM);
            ROLLBACK;
            RETURN messages_t('stock_available', json_object('success' VALUE false));
    END wait_for_available_balance;

END aq_p;