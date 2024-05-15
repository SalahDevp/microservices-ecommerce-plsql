create or replace PACKAGE main_p AS

    PROCEDURE add_user(
        p_name IN VARCHAR2,
        p_phone IN VARCHAR2,
        p_address IN VARCHAR2,
        p_initial_balance IN NUMBER
    );

    PROCEDURE delete_user(
        p_id IN NUMBER
    );

    PROCEDURE add_balance(
        p_id IN NUMBER,
        p_amount IN NUMBER
    );

    PROCEDURE subtract_balance(
        p_id IN NUMBER,
        p_amount IN NUMBER
    );
    
    FUNCTION get_users RETURN SYS_REFCURSOR;
    
     PROCEDURE handle_payment(
    p_order_id IN NUMBER,
    p_customer_id IN NUMBER,
    p_price IN NUMBER
    );
        

END main_p;



create or replace PACKAGE BODY main_p AS

    PROCEDURE add_user(
        p_name IN VARCHAR2,
        p_phone IN VARCHAR2,
        p_address IN VARCHAR2,
        p_initial_balance IN NUMBER
    ) AS
    BEGIN
        INSERT INTO users (name,phone, address, balance)
        VALUES (p_name,p_phone, p_address, p_initial_balance);
        COMMIT;
        dbms_output.put_line('User ' || p_name || ' added successfully with initial balance ' || p_initial_balance);
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line('Error adding user: ' || sqlerrm);
    END add_user;
    
    FUNCTION get_users RETURN SYS_REFCURSOR IS
        curs SYS_REFCURSOR;
        BEGIN
        OPEN curs FOR SELECT * FROM users;
        RETURN curs;
    END get_users;

    PROCEDURE delete_user(
        p_id IN NUMBER
    ) AS
    BEGIN
        DELETE FROM users
        WHERE id = p_id;
        COMMIT;
        dbms_output.put_line('User with ID ' || p_id || ' deleted successfully');
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line('Error deleting user: ' || sqlerrm);
    END delete_user;

    PROCEDURE add_balance(
        p_id IN NUMBER,
        p_amount IN NUMBER
    ) AS
    BEGIN
        UPDATE users
        SET balance = balance + p_amount
        WHERE id = p_id;
        COMMIT;
        dbms_output.put_line(p_amount || ' added to balance of user ID ' || p_id);
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line('Error adding balance: ' || sqlerrm);
    END add_balance;

    PROCEDURE subtract_balance(
        p_id IN NUMBER,
        p_amount IN NUMBER
    ) AS
    BEGIN
        UPDATE users
        SET balance = balance - p_amount
        WHERE id = p_id;
        COMMIT;
        dbms_output.put_line(p_amount || ' subtracted from balance of user ID ' || p_id);
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line('Error subtracting balance: ' || sqlerrm);
    END subtract_balance;
    
    PROCEDURE handle_payment(
    p_order_id IN NUMBER,
    p_customer_id IN NUMBER,
    p_price IN NUMBER
    ) IS
        l_balance users.balance%type;
        balance_exception EXCEPTION;
        message_payload CLOB;
        l_order_success BOOLEAN;
    BEGIN
        SELECT balance INTO l_balance FROM users 
        WHERE id = p_customer_id FOR UPDATE;
        
        IF p_price > l_balance THEN
            RAISE balance_exception;
        END IF;
        

        UPDATE users SET balance = balance - p_price WHERE id = p_customer_id;
        COMMIT;
        
        message_payload := json_object(
            'success' VALUE 'true',
            'order_id' VALUE p_order_id
        );

        aq_p.publish_event('balance_available', message_payload);
        
        --wait for order success
        l_order_success := aq_p.wait_for_order_success(p_order_id);
        
        ---- SAGA compensating transaction
        IF NOT l_order_success THEN
            UPDATE users SET balance = balance + p_price WHERE id = p_customer_id;
        END IF;
        COMMIT;

    EXCEPTION
        WHEN balance_exception THEN
            message_payload := json_object('success' VALUE false, 'error' VALUE 'Insufficient balance', 'order_id' VALUE p_order_id);
            aq_p.publish_event('balance_available', message_payload);
            ROLLBACK;
            RAISE;
        WHEN OTHERS THEN
            message_payload := json_object('success' VALUE false, 'error' VALUE SQLERRM, 'order_id' VALUE p_order_id);
            aq_p.publish_event('balance_available', message_payload);
            ROLLBACK;
            RAISE;
    END handle_payment;


END main_p;