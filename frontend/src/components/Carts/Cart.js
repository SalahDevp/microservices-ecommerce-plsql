import React, { useState, useEffect, useMemo, useRef } from "react";
import { useTable } from "react-table";
import { useNavigate } from "react-router-dom";
import CartEntry from "./CartEntry";
import CartService from "../../services/CartService";
import { useParams } from "react-router-dom";
import OrdersService from "../../services/OrdersService";

const CartEntriesList = () => {
  const { id } = useParams();
  const customer_id = id;
  const navigate = useNavigate();
  const [CartEntries, setCartEntries] = useState([]);
  const [selectedCartEntryForEdit, setSelectedCartEntryForEdit] =
    useState(null);
  const CartEntriesRef = useRef();

  CartEntriesRef.current = CartEntries;

  useEffect(() => {
    retrieveCartEntries();
  }, []);

  const retrieveCartEntries = () => {
    CartService.getCustomerCart(customer_id)
      .then((response) => {
        console.log(response);
        setCartEntries(response.data);
      })
      .catch((e) => {
        console.log(e);
      });
  };

  const openCartEntryForEdit = (rowIndex) => {
    setSelectedCartEntryForEdit(CartEntriesRef.current[rowIndex]);
  };

  const handleReduceQuantity = () => {
    setSelectedCartEntryForEdit(null);
    retrieveCartEntries();
  };

  const columns = useMemo(
    () => [
      {
        Header: "Product ID",
        accessor: "product_id",
      },
      {
        Header: "Quantity",
        accessor: "quantity",
      },
      {
        Header: "Actions",
        accessor: "actions",
        Cell: ({ row }) => (
          <div>
            <span onClick={() => openCartEntryForEdit(row.id)}>
              <i className="far fa-edit action mr-2"></i>
            </span>
          </div>
        ),
      },
    ],
    []
  );

  const { getTableProps, getTableBodyProps, headerGroups, rows, prepareRow } =
    useTable({
      columns,
      data: CartEntries,
    });
  const handleAddCartEntry = () => {
    navigate("/products/");
  };
  const deleteCart = () => {
    CartService.deleteCustomerCart(customer_id)
      .then((response) => {
        console.log(response);
        setCartEntries([]);
      })
      .catch((e) => {
        console.log(e);
      });
  };
  const handleOrder = () => {
    OrdersService.order(customer_id, CartEntries)
      .then((response) => {
        console.log(response);
        setCartEntries([]);
      })
      .catch((e) => {
        console.log(e);
      });
  };
  return (
    <div className="list row">
      <div className="col-md-12 list">
        <h4>Customer's Cart</h4>
        <table
          className="table table-striped table-bordered"
          {...getTableProps()}
        >
          <thead>
            {headerGroups.map((headerGroup) => (
              <tr {...headerGroup.getHeaderGroupProps()}>
                {headerGroup.headers.map((column) => (
                  <th key={column.id} {...column.getHeaderProps()}>
                    {column.render("Header")}
                  </th>
                ))}
              </tr>
            ))}
          </thead>
          <tbody {...getTableBodyProps()}>
            {rows.map((row, i) => {
              prepareRow(row);
              return (
                <tr key={row.id} {...row.getRowProps()}>
                  {row.cells.map((cell) => (
                    <td {...cell.getCellProps()}>{cell.render("Cell")}</td>
                  ))}
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>

      <div className="col-md-8">
        <button
          className="btn btn-sm btn-primary"
          style={{ marginLeft: "8px" }}
          onClick={handleAddCartEntry}
        >
          Add a product / quantity
        </button>
        <button
          className="btn btn-sm btn-primary"
          style={{ marginLeft: "8px" }}
          onClick={handleOrder}
        >
          Order
        </button>
        <button
          className="btn btn-sm btn-danger"
          onClick={deleteCart}
          style={{ marginLeft: "8px" }}
        >
          Delete The Cart
        </button>
      </div>

      {selectedCartEntryForEdit && (
        <CartEntry
          cartEntry={selectedCartEntryForEdit}
          handleReduceQuantity={handleReduceQuantity}
        />
      )}
    </div>
  );
};

export default CartEntriesList;
