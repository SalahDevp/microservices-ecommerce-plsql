import React, { useState } from "react";
import CustomerDataService from "../../services/CustomersService";
import { useNavigate } from "react-router-dom";

const Customer = ({ Customer, handleDeleteCustomer, handleUpdateCustomer }) => {
  const navigate = useNavigate();

  const [currentCustomer, setCurrentCustomer] = useState(Customer);
  const [message, setMessage] = useState("");
  const [balance, setBalance] = useState(0);

  const handleInputChange = (event) => {
    const { name, value } = event.target;
    setCurrentCustomer({ ...currentCustomer, [name]: value });
  };

  const updateCustomer = () => {
    console.log(balance);
    CustomerDataService.updateBalance(currentCustomer.id, {
      balance_change: balance,
    })
      .then((response) => {
        currentCustomer.balance += parseInt(balance);
        handleUpdateCustomer(currentCustomer);
        setMessage("The Customer was updated successfully!");
      })
      .catch((error) => {
        console.log(error);
      });
  };

  const deleteCustomer = () => {
    CustomerDataService.remove(currentCustomer.id)
      .then((response) => {
        handleDeleteCustomer(currentCustomer.id);
      })
      .catch((error) => {
        console.log(error);
      });
  };

  return (
    <div style={{ marginTop: "10px" }}>
      {currentCustomer ? (
        <div className="edit-form">
          <h4>Edit Customer Balance</h4>
          <form>
            <div className="form-group">
              <label htmlFor="id">Customer id</label>
              <input
                type="text"
                className="form-control"
                id="id"
                name="id"
                disabled={true}
                value={currentCustomer.id}
                onChange={handleInputChange}
              />
            </div>
            <div className="form-group">
              <label htmlFor="name">Name</label>
              <input
                type="text"
                className="form-control"
                id="name"
                name="name"
                disabled={true}
                value={currentCustomer.name}
                onChange={handleInputChange}
              />
            </div>
            <div className="form-group">
              <label htmlFor="phone">Phone</label>
              <input
                type="text"
                className="form-control"
                id="phone"
                name="phone"
                disabled={true}
                value={currentCustomer.phone}
                onChange={handleInputChange}
              />
            </div>
            <div className="form-group">
              <label htmlFor="address">Address</label>
              <input
                type="text"
                className="form-control"
                id="address"
                name="address"
                disabled={true}
                value={currentCustomer.address}
                onChange={handleInputChange}
              />
            </div>
            <div className="form-group">
              <label htmlFor="balance">
                Increment or substruct current balance by
              </label>
              <input
                type="number"
                className="form-control"
                id="balance"
                name="balance"
                onChange={(event) => {
                  const { name, value } = event.target;
                  setBalance(value);
                }}
              />
            </div>
          </form>

          <button
            type="submit"
            className="badge badge-success"
            onClick={updateCustomer}
          >
            Update
          </button>

          <button className="badge badge-danger mr-2" onClick={deleteCustomer}>
            Delete Customer
          </button>

          <p>{message}</p>
        </div>
      ) : (
        <div>
          <br />
          <p>Please click on a Customer...</p>
        </div>
      )}
    </div>
  );
};

export default Customer;
