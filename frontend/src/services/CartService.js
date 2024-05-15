import http from "../http-common";

const CartService = {
  getCustomerCart: (customer_id) => {
    return http.get(`/carts/${customer_id}`);
  },
  deleteCustomerCart: (customer_id) => {
    return http.delete(`/carts/${customer_id}`);
  },
  addProductCart: (customer_id, product_id, data) => {
    return http.put(`/carts/${customer_id}/products/${product_id}`, data);
  },
  removeQuantityProductCart: (customer_id, product_id, data) => {
    return http.put(`/carts/${customer_id}/products/${product_id}`, data);
  },
};

export default CartService;
