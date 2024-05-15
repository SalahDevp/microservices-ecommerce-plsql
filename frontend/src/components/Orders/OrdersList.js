import React, { useState, useEffect, useMemo, useRef } from "react";
import CustomerDataService from "../../services/OrdersService";
import { useTable } from "react-table";

const OrdersList = (props) => {
  const [Orders, setOrders] = useState([]);
  const OrdersRef = useRef();

  OrdersRef.current = Orders;

  useEffect(() => {
    retrieveOrders();
  }, []);

  const retrieveOrders = () => {
    CustomerDataService.getAll()
      .then((response) => {
        console.log(response);
        setOrders(response.data);
      })
      .catch((e) => {
        console.log(e);
      });
  };

  const columns = useMemo(
    () => [
      {
        Header: "Customer ID",
        accessor: "customer_id",
      },
      {
        Header: "Product ID",
        accessor: "product_id",
      },
      {
        Header: "Quantity",
        accessor: "quantity",
      },
    ],
    []
  );

  const { getTableProps, getTableBodyProps, headerGroups, rows, prepareRow } =
    useTable({
      columns,
      data: Orders,
    });
  return (
    <div className="list row">
      <div className="col-md-12 list">
        <h4>Orders List</h4>
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
    </div>
  );
};

export default OrdersList;
