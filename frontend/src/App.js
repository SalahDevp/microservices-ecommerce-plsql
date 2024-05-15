import React from "react";
import { Routes, Route, Link } from "react-router-dom";
import "bootstrap/dist/css/bootstrap.min.css";
import "@fortawesome/fontawesome-free/css/all.css";
import "@fortawesome/fontawesome-free/js/all.js";
import "./App.css";

import ProductsList from "./components/Products/ProductsList";
import AddProduct from "./components/Products/AddProduct";
import CustomersList from "./components/Customers/CustomersList";
import AddCustomer from "./components/Customers/AddCustomer";
import CartEntriesList from "./components/Carts/Cart";
import OrdersList from "./components/Orders/OrdersList";

function App() {
  return (
    <div>
      <nav className="navbar navbar-expand navbar-dark bg-dark">
        <a href="/" className="navbar-brand" style={{ marginLeft: "8px" }}>
          Projet BDA
        </a>
        <div className="navbar-nav mr-auto">
          <li className="nav-item">
            <Link to={"/products"} className="nav-link">
              Products
            </Link>
          </li>
          <li className="nav-item">
            <Link to={"/customers"} className="nav-link">
              Customers
            </Link>
          </li>
          <li className="nav-item">
            <Link to={"/orders"} className="nav-link">
              Orders
            </Link>
          </li>
        </div>
      </nav>

      <div className="container mt-3">
        <Routes>
          <Route path="/" element={<ProductsList />} />
          <Route path="/products" element={<ProductsList />} />
          <Route path="/products/add" element={<AddProduct />} />
          <Route path="/customers" element={<CustomersList />} />
          <Route path="/customers/add" element={<AddCustomer />} />
          <Route path="/customers/:id/cart" element={<CartEntriesList />} />
          <Route path="/orders" element={<OrdersList />} />
        </Routes>
      </div>
    </div>
  );
}

export default App;
