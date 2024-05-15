create or replace PACKAGE main_p AS

    PROCEDURE handle_check_stock(
    order_id IN NUMBER,
    product_id IN products.id%TYPE,
    quantity IN products.stock%TYPE
    );
    
    PROCEDURE insert_product (
        p_product_code IN VARCHAR2,
        p_name IN VARCHAR2,
        p_description IN VARCHAR2,
        p_category_id IN NUMBER,
        p_price IN NUMBER,
        p_stock IN NUMBER
    );

    FUNCTION get_all_products RETURN SYS_REFCURSOR;


   PROCEDURE edit_product (
    p_id IN NUMBER,
    p_product_code IN VARCHAR2,
    p_name IN VARCHAR2 DEFAULT NULL,
    p_description IN VARCHAR2 DEFAULT NULL,
    p_category_id IN INTEGER DEFAULT NULL,
    p_price IN NUMBER DEFAULT NULL,
    p_stock IN NUMBER DEFAULT NULL
);

    PROCEDURE delete_product (
        p_id IN NUMBER
    );

    PROCEDURE update_stock(
        p_product_id IN products.id%TYPE,
        p_added_quantity IN products.stock%TYPE
    );

END main_p;



create or replace PACKAGE BODY main_p AS
    
    PROCEDURE handle_check_stock(
    order_id IN NUMBER,
    product_id IN products.id%TYPE,
    quantity IN products.stock%TYPE
    ) IS
        product_stock products.stock%type;
        stock_exception EXCEPTION;
        message_payload CLOB;
        unit_price NUMBER;
        total_price NUMBER;
        l_order_success BOOLEAN;
    BEGIN
        SELECT stock, price INTO product_stock, unit_price FROM products 
        WHERE id = product_id FOR UPDATE;
        
        IF quantity > product_stock THEN
            RAISE stock_exception;
        END IF;
        

        UPDATE products SET stock = stock - quantity WHERE id = product_id;
        COMMIT;
        --calc total price
         total_price := unit_price * quantity;

        message_payload := json_object(
            'success' VALUE 'true',
            'total_price' VALUE total_price,
            'order_id' VALUE order_id
        );

        aq_p.publish_event('stock_available', message_payload);
        
        --wait for order success
        l_order_success := aq_p.wait_for_order_success(order_id);
        ---- SAGA compensating transaction
        IF NOT l_order_success THEN
            UPDATE products SET stock = stock + quantity WHERE id = product_id;
        END IF;
        COMMIT;

    EXCEPTION
        WHEN stock_exception THEN
            message_payload := json_object('success' VALUE false, 'error' VALUE 'Insufficient stock', 'order_id' VALUE order_id);
            aq_p.publish_event('stock_available', message_payload);
            ROLLBACK;
            RAISE;
        WHEN OTHERS THEN
            message_payload := json_object('success' VALUE false, 'error' VALUE SQLERRM, 'order_id' VALUE order_id);
            aq_p.publish_event('stock_available', message_payload);
            ROLLBACK;
            RAISE;
    END handle_check_stock;


--add a new product 

PROCEDURE insert_product (
    p_product_code IN VARCHAR2,
    p_name IN VARCHAR2,
    p_description IN VARCHAR2,
    p_category_id IN NUMBER,
    p_price IN NUMBER,
    p_stock IN NUMBER
) IS

    v_category_name VARCHAR2(200);
BEGIN
    -- Insert data into the product table
    INSERT INTO products (product_code, name, description, category_id, price, stock)
    VALUES (p_product_code, p_name, p_description, p_category_id, p_price, p_stock);

    -- Retrieve the category name based on the category_id
    SELECT name INTO v_category_name FROM categories WHERE id = p_category_id;


    COMMIT;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Category not found for category_id: ' || p_category_id);
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;

--get all products
FUNCTION get_all_products RETURN SYS_REFCURSOR AS
    c_products SYS_REFCURSOR;
BEGIN
    OPEN c_products FOR
    SELECT * FROM products;
    RETURN c_products;
END get_all_products;


PROCEDURE edit_product (
    p_id IN NUMBER,
    p_product_code IN VARCHAR2,
    p_name IN VARCHAR2 DEFAULT NULL,
    p_description IN VARCHAR2 DEFAULT NULL,
    p_category_id IN INTEGER DEFAULT NULL,
    p_price IN NUMBER DEFAULT NULL,
    p_stock IN NUMBER DEFAULT NULL
) AS
BEGIN
    UPDATE products
    SET name = COALESCE(p_name, name),
        description = COALESCE(p_description, description),
        category_id = COALESCE(p_category_id, category_id),
        price = COALESCE(p_price, price),
        stock = COALESCE(p_stock, stock),
        product_code = p_product_code
        WHERE id = p_id;

    COMMIT;
END edit_product;




--delete product
PROCEDURE delete_product (
    p_id IN NUMBER
) AS
BEGIN
    DELETE FROM products
    WHERE id = p_id;

    COMMIT; -- Commit the transaction
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK; -- Rollback the transaction if an error occurs
        RAISE; -- Raise the exception to the caller
END delete_product;


--update stock
PROCEDURE update_stock(p_product_id IN products.id%type, p_added_quantity IN products.stock%TYPE) IS
BEGIN
    UPDATE products SET stock = stock + p_added_quantity
    WHERE id = p_product_id;
    COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
END update_stock;

END main_p;