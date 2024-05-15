create or replace PROCEDURE event_listener (
    context    RAW,
    reginfo    SYS.AQ$_REG_INFO,
    descr      SYS.AQ$_DESCRIPTOR,
    payload    RAW,
    payloadl   NUMBER
) IS
    l_dequeue_options    dbms_aq.dequeue_options_t;
    l_message_properties dbms_aq.message_properties_t;
    l_message_handle     RAW(16);
    l_payload            messages_t;
    l_error_message      VARCHAR2(4000);
BEGIN
    l_dequeue_options.msgid := descr.msg_id;
    l_dequeue_options.wait := dbms_aq.no_wait;
    l_dequeue_options.consumer_name := 'customers_service';
    dbms_aq.dequeue(
        queue_name         => descr.queue_name,
        dequeue_options    => l_dequeue_options,
        message_properties => l_message_properties,
        payload            => l_payload,
        msgid              => l_message_handle
    );
    IF l_payload.event_type = 'check_balance' THEN
        main_p.handle_payment(
        TO_NUMBER(json_value(l_payload.payload, '$.order_id')),
            TO_NUMBER(json_value(l_payload.payload, '$.customer_id')),
            TO_NUMBER(json_value(l_payload.payload, '$.price'))
        );
    END IF;
    COMMIT;


END event_listener;



BEGIN
   dbms_aq.register
      (sys.aq$_reg_info_list
         (sys.aq$_reg_info
            ('customers_service.customers_queue:customers_service' -- the queue 
            ,DBMS_AQ.NAMESPACE_AQ
            ,'plsql://customers_service.EVENT_LISTENER' -- this is the routine that will get called when a message is queued
            ,NULL)
         ),
      1
      );
END;
        
        
        