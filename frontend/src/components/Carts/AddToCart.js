import React, { useEffect, useState } from "react";
import CartService from "../../services/CartService";

const AddToCart = ({ product, handleAddToCart }) => {
  console.log(product);
  const initialCartEntryState = {
    customer_id: 0,
    product_id: 0,
    quantity: 0,
  };
  const [cartEntry, setCartEntry] = useState({
    customer_id: 0,
    product_id: product.id,
    quantity: 1,
  });
  console.log(cartEntry);
  const [submitted, setSubmitted] = useState(false);

  useEffect(() => {
    setCartEntry({
      customer_id: 0,
      product_id: product.id,
      quantity: 1,
    });
  }, [product]);

  const handleInputChange = (event) => {
    const { name, value } = event.target;
    setCartEntry({ ...cartEntry, [name]: value });
  };

  const saveCartEntry = () => {
    CartService.addProductCart(cartEntry.customer_id, cartEntry.product_id, {
      quantity: cartEntry.quantity,
      delete: false,
    })
      .then((response) => {
        console.log(response.data);
        handleAddToCart();
        setSubmitted(true);
      })
      .catch((e) => {
        console.log(e);
      });
  };

  const newCartEntry = () => {
    setCartEntry(initialCartEntryState);
    setSubmitted(false);
  };

  return (
    <div className="submit-form" style={{ marginTop: "10px" }}>
      {submitted ? (
        <div>
          <h4>You submitted successfully!</h4>
          <button className="btn btn-success" onClick={newCartEntry}>
            Add Another Cart Entry
          </button>
        </div>
      ) : (
        <div>
          <div className="form-group">
            <label htmlFor="product_id">Product Id</label>
            <input
              type="number"
              className="form-control"
              id="product_id"
              disabled={true}
              value={cartEntry.product_id}
              name="product_id"
            />
          </div>

          <div className="form-group">
            <label htmlFor="customer_id">Customer ID</label>
            <input
              type="number"
              className="form-control"
              id="customer_id"
              required
              value={cartEntry.customer_id}
              onChange={handleInputChange}
              name="customer_id"
            />
          </div>

          <div className="form-group">
            <label htmlFor="quantity">Quantity</label>
            <input
              type="number"
              className="form-control"
              id="quantity"
              required
              value={cartEntry.quantity}
              onChange={handleInputChange}
              name="quantity"
            />
          </div>

          <button
            onClick={saveCartEntry}
            className="btn btn-success"
            style={{ marginTop: "10px" }}
          >
            Add to cart
          </button>
        </div>
      )}
    </div>
  );
};

export default AddToCart;
