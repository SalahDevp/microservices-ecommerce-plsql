import http from "../http-common";

const OrdersService = {
  getAll: () => {
    return http.get(`/orders`);
  },
  order: (customer_id, data) => {
    return http.post(`/orders/${customer_id}`, data);
  },
};

export default OrdersService;
