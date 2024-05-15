import React, { useState } from "react";
import ProductDataService from "../../services/ProductsService";
import { useNavigate } from "react-router-dom";

const AddProduct = () => {
  const initialProductState = {
    product_code: "",
    name: "",
    description: "",
    category_id: 0,
    price: 0,
    stock: 0,
  };
  const navigate = useNavigate();
  const [product, setProduct] = useState(initialProductState);
  const [submitted, setSubmitted] = useState(false);

  const handleInputChange = (event) => {
    const { name, value } = event.target;
    setProduct({ ...product, [name]: value });
  };

  const saveProduct = () => {
    ProductDataService.create(product)
      .then((response) => {
        setProduct(initialProductState);
        setSubmitted(true);
        navigate("/products/");
        console.log(response.data);
      })
      .catch((e) => {
        console.log(e);
      });
  };

  const newProduct = () => {
    setProduct(initialProductState);
    setSubmitted(false);
  };

  return (
    <div className="submit-form" style={{ marginTop: "10px" }}>
      <h4>Add Product</h4>
      {submitted ? (
        <div>
          <h4>You submitted successfully!</h4>
          <button className="btn btn-success" onClick={newProduct}>
            Add Another Product
          </button>
        </div>
      ) : (
        <div>
          <div className="form-group">
            <label htmlFor="product_code">Product Code</label>
            <input
              type="text"
              className="form-control"
              id="product_code"
              required
              value={product.product_code}
              onChange={handleInputChange}
              name="product_code"
            />
          </div>

          <div className="form-group">
            <label htmlFor="name">Name</label>
            <input
              type="text"
              className="form-control"
              id="name"
              required
              value={product.name}
              onChange={handleInputChange}
              name="name"
            />
          </div>

          <div className="form-group">
            <label htmlFor="description">Description</label>
            <input
              type="text"
              className="form-control"
              id="description"
              required
              value={product.description}
              onChange={handleInputChange}
              name="description"
            />
          </div>

          <div className="form-group">
            <label htmlFor="category_id">Category ID</label>
            <input
              type="number"
              className="form-control"
              id="category_id"
              required
              value={product.category_id}
              onChange={handleInputChange}
              name="category_id"
            />
          </div>

          <div className="form-group">
            <label htmlFor="price">Price</label>
            <input
              type="number"
              className="form-control"
              id="price"
              required
              value={product.price}
              onChange={handleInputChange}
              name="price"
            />
          </div>

          <div className="form-group">
            <label htmlFor="stock">Stock</label>
            <input
              type="number"
              className="form-control"
              id="stock"
              required
              value={product.stock}
              onChange={handleInputChange}
              name="stock"
            />
          </div>
          <button
            onClick={saveProduct}
            className="btn btn-success"
            style={{ marginTop: "10px" }}
          >
            Submit
          </button>
        </div>
      )}
    </div>
  );
};

export default AddProduct;
