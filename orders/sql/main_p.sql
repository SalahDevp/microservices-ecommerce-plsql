create or replace PACKAGE main_p AS

    PROCEDURE create_order(
        product_id IN INT,
        customer_id IN INT,
        quantity IN INT
    );

    PROCEDURE add_product_cart(
        p_customer_id carts.customer_id%type,
        p_product_id carts.product_id%type,
        p_product_quantity carts.quantity%type DEFAULT 1
    );

    PROCEDURE remove_product_cart(
        p_customer_id carts.customer_id%type,
        p_product_id carts.product_id%type,
        p_remove_quantity carts.quantity%type DEFAULT 1
    );

    FUNCTION get_cart(
        p_customer_id carts.customer_id%type
    ) RETURN sys_refcursor;

    PROCEDURE clear_cart(
        p_customer_id carts.customer_id%type
    );
    
    PROCEDURE order_cart(p_customer_id INT);
    
    function get_orders return sys_refcursor;

END main_p;


create or replace PACKAGE BODY main_p AS
    
    PROCEDURE create_order(
        product_id IN INT,
        customer_id IN INT,
        quantity IN INT
        ) IS
        
        message_payload CLOB;
        is_success BOOLEAN;
        l_new_order_id NUMBER;
        l_products_message messages_t;
        l_customers_message messages_t;
        l_order_failed EXCEPTION;
        l_price NUMBER;
        BEGIN

        INSERT INTO orders(product_id, customer_id, quantity)
        VALUES (product_id, customer_id, quantity)
        RETURNING id INTO l_new_order_id;
        message_payload := json_object('product_id' VALUE product_id,
                                        'quantity' VALUE quantity,
                                        'order_id' VALUE l_new_order_id);
        aq_p.publish_event('check_stock', message_payload);

        l_products_message := aq_p.wait_for_available_stock(l_new_order_id);
        
        IF NOT (json_value(l_products_message.payload, '$.success') = 'true') THEN
            RAISE_APPLICATION_ERROR(-20001,json_value(l_products_message.payload, '$.error'));
        END IF;
        
        l_price := json_value(l_products_message.payload, '$.total_price');
        
        message_payload := json_object('customer_id' VALUE customer_id,
                                        'order_id' VALUE l_new_order_id,
                                        'price' VALUE l_price);
                                    
        aq_p.publish_event('check_balance', message_payload);
        l_customers_message := aq_p.wait_for_available_balance(l_new_order_id);
        
        IF NOT (json_value(l_customers_message.payload, '$.success') = 'true') THEN
            RAISE_APPLICATION_ERROR(-20001,json_value(l_customers_message.payload, '$.error'));
        END IF;
        
        message_payload := json_object('success' VALUE 'true',
                                        'order_id' VALUE l_new_order_id);
        aq_p.publish_event('order_success', message_payload);

        
        COMMIT;

        EXCEPTION
            WHEN OTHERS THEN
            message_payload := json_object('success' VALUE 'false',
                                        'order_id' VALUE l_new_order_id);
            
            aq_p.publish_event('order_success', message_payload);
            -- SAGA compensating transactions
            DELETE FROM orders WHERE id = l_new_order_id;
            DBMS_OUTPUT.PUT_LINE('ERROR while creating order: ' || SQLERRM);
            COMMIT;
            
            
    END create_order;

  procedure add_product_cart(p_customer_id       carts.customer_id%type,
                               p_product_id    carts.product_id%type,
                               p_product_quantity carts.quantity%type default 1) is
  begin
  -- update quantity if already exists
    update carts
    set quantity = quantity + p_product_quantity
    where customer_id = p_customer_id and product_id = p_product_id;

    -- add product to cart
    if sql%notfound then
       insert into carts(customer_id, product_id, quantity)
       values ( p_customer_id, p_product_id, p_product_quantity);
       end if;
       commit;
       dbms_output.put_line('Product added successfuly');
       exception
         when others then
           dbms_output.put_line('Error: ' || sqlerrm);
           rollback;
  end add_product_cart;


 procedure remove_product_cart(p_customer_id    carts.customer_id%type,
                                  p_product_id carts.product_id%type,
                                  p_remove_quantity carts.quantity%type DEFAULT 1) is
  l_product_count carts.quantity%type;
  begin
        update carts
        set quantity = quantity - p_remove_quantity
        where customer_id = p_customer_id and product_id = p_product_id;

        select quantity
        into l_product_count
        from carts
        where customer_id = p_customer_id and product_id = p_product_id;

        if l_product_count < 1 then
          delete from carts
          where customer_id = p_customer_id and product_id = p_product_id;
          end if;
          commit;
          dbms_output.put_line('Cart updated');
          exception
             when others then
             dbms_output.put_line('Error: ' || sqlerrm);
             rollback;
  end remove_product_cart;

   function get_cart(p_customer_id carts.customer_id%type) return sys_refcursor is
    curs sys_refcursor;
  begin
    open curs for
      select customer_id, product_id, quantity
      from carts
      where customer_id = p_customer_id;
    return curs;
  end;

  PROCEDURE clear_cart(p_customer_id carts.customer_id%type) is
    BEGIN
    DELETE FROM carts WHERE customer_id = p_customer_id;
    COMMIT;
    END clear_cart;
    
    PROCEDURE order_cart(p_customer_id INT) IS
    BEGIN
        FOR cart_rec IN (SELECT product_id, quantity FROM carts WHERE customer_id = p_customer_id)
        LOOP
            -- Call create_order procedure for each item in the cart
            create_order(
                product_id  => cart_rec.product_id,
                customer_id => p_customer_id,
                quantity    => cart_rec.quantity
            );
        END LOOP;
    
        -- clear the cart after ordering
        clear_cart(p_customer_id);
        COMMIT;
    
        
    EXCEPTION
        WHEN OTHERS THEN
           
            DBMS_OUTPUT.PUT_LINE('Error occurred: ' || SQLERRM);
            ROLLBACK;
    END order_cart;
    
    
    function get_orders return sys_refcursor is
    curs sys_refcursor;
  begin
    open curs for
      select customer_id, product_id, quantity
      from orders;
    return curs;
  end;

END main_p;