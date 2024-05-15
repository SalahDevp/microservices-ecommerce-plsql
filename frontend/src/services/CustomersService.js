import http from "../http-common";

const getAll = () => {
  return http.get("/customers");
};

const create = (data) => {
  return http.post("/customers", data);
};

const updateBalance = (id, data) => {
  return http.put(`/customers/${id}`, data);
};

const remove = (id) => {
  return http.delete(`/customers/${id}`);
};

const customerService = {
  getAll,
  create,
  updateBalance,
  remove,
};

export default customerService;
