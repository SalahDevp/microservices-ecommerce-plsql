import React, { useState } from "react";
import ProductDataService from "../../services/ProductsService";
import { useNavigate } from "react-router-dom";

const Product = ({ product, handleDeleteProduct, handleUpdateProduct }) => {
  const navigate = useNavigate();

  const [currentProduct, setCurrentProduct] = useState(product);
  const [message, setMessage] = useState("");

  const handleInputChange = (event) => {
    const { name, value } = event.target;
    setCurrentProduct({ ...currentProduct, [name]: value });
  };

  const updateProduct = () => {
    ProductDataService.update(currentProduct.id, currentProduct)
      .then((response) => {
        handleUpdateProduct(currentProduct);
        setMessage("The Product was updated successfully!");
      })
      .catch((error) => {
        console.log(error);
      });
  };

  const deleteProduct = () => {
    ProductDataService.remove(currentProduct.id)
      .then((response) => {
        handleDeleteProduct(currentProduct.id);
      })
      .catch((error) => {
        console.log(error);
      });
  };

  return (
    <div style={{ marginTop: "10px" }}>
      {currentProduct ? (
        <div className="edit-form">
          <h4>Edit Product</h4>
          <form>
            <div className="form-group">
              <label htmlFor="product_code">Product Code</label>
              <input
                type="text"
                className="form-control"
                id="product_code"
                name="product_code"
                value={currentProduct.product_code}
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
                value={currentProduct.name}
                onChange={handleInputChange}
              />
            </div>
            <div className="form-group">
              <label htmlFor="description">Description</label>
              <input
                type="text"
                className="form-control"
                id="description"
                name="description"
                value={currentProduct.description}
                onChange={handleInputChange}
              />
            </div>
            <div className="form-group">
              <label htmlFor="category_id">Category ID</label>
              <input
                type="number"
                className="form-control"
                id="category_id"
                name="category_id"
                value={currentProduct.category_id}
                onChange={handleInputChange}
              />
            </div>
            <div className="form-group">
              <label htmlFor="price">Price</label>
              <input
                type="number"
                className="form-control"
                id="price"
                name="price"
                value={currentProduct.price}
                onChange={handleInputChange}
              />
            </div>
            <div className="form-group">
              <label htmlFor="stock">Stock</label>
              <input
                type="number"
                className="form-control"
                id="stock"
                name="stock"
                value={currentProduct.stock}
                onChange={handleInputChange}
              />
            </div>
          </form>

          <button
            type="submit"
            className="badge badge-success"
            onClick={updateProduct}
          >
            Update
          </button>

          <button className="badge badge-danger mr-2" onClick={deleteProduct}>
            Delete Product
          </button>

          <p>{message}</p>
        </div>
      ) : (
        <div>
          <br />
          <p>Please click on a Product...</p>
        </div>
      )}
    </div>
  );
};

export default Product;
