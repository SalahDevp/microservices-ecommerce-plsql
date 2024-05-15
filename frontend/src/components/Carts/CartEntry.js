import React, { useState } from "react";
import CartService from "../../services/CartService";

const CartEntry = ({ cartEntry, handleReduceQuantity }) => {
  const [currentCartEntry, setCurrentCartEntry] = useState(cartEntry);
  const [message, setMessage] = useState("");

  const handleInputChange = (event) => {
    const { name, value } = event.target;
    setCurrentCartEntry({ ...currentCartEntry, [name]: value });
  };

  const reduceQuantity = () => {
    console.log(currentCartEntry);
    console.log(Number(currentCartEntry.quantity));
    CartService.removeQuantityProductCart(
      currentCartEntry.customer_id,
      currentCartEntry.product_id,
      { quantity: Number(currentCartEntry.quantity), delete: true }
    )
      .then((response) => {
        handleReduceQuantity();
      })
      .catch((error) => {
        console.log(error);
      });
  };

  return (
    <div style={{ marginTop: "10px" }}>
      {currentCartEntry ? (
        <div className="edit-form">
          <h4>Cart Entry</h4>
          <form>
            <div className="form-group">
              <label htmlFor="product_id">Product ID</label>
              <input
                type="number"
                className="form-control"
                id="product_id"
                name="product_id"
                disabled={true}
                value={currentCartEntry.product_id}
                onChange={handleInputChange}
              />
            </div>
            <div className="form-group">
              <label htmlFor="quantity">Reduce Quantity by</label>
              <input
                type="number"
                className="form-control"
                id="quantity"
                name="quantity"
                value={currentCartEntry.quantity}
                onChange={handleInputChange}
              />
            </div>
          </form>

          <button
            type="submit"
            className="badge badge-success"
            onClick={reduceQuantity}
          >
            Reduce Quantity
          </button>

          <p>{message}</p>
        </div>
      ) : (
        <div>
          <br />
          <p>Please click on a Cart Entry...</p>
        </div>
      )}
    </div>
  );
};

export default CartEntry;
