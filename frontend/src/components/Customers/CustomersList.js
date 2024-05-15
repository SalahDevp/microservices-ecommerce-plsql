import React, { useState, useEffect, useMemo, useRef } from "react";
import CustomerDataService from "../../services/CustomersService";
import { useTable } from "react-table";
import { useNavigate } from "react-router-dom";
import Customer from "./Customer";

const CustomersList = (props) => {
  const navigate = useNavigate();
  const [Customers, setCustomers] = useState([]);
  const [selectedCustomer, setSelectedCustomer] = useState(null);
  const CustomersRef = useRef();

  CustomersRef.current = Customers;

  useEffect(() => {
    retrieveCustomers();
  }, []);

  const retrieveCustomers = () => {
    CustomerDataService.getAll()
      .then((response) => {
        console.log(response);
        setCustomers(response.data);
      })
      .catch((e) => {
        console.log(e);
      });
  };

  const openCustomer = (rowIndex) => {
    setSelectedCustomer(CustomersRef.current[rowIndex]);
  };

  const handleDeleteCustomer = (CustomerId) => {
    CustomerDataService.remove(CustomerId)
      .then((response) => {
        setCustomers((prevCustomers) =>
          prevCustomers.filter((Customer) => Customer.id !== CustomerId)
        );
        setSelectedCustomer(null);
      })
      .catch((error) => {
        console.log(error);
      });
  };

  const handleUpdateCustomer = (updatedCustomer) => {
    const index = Customers.findIndex(
      (Customer) => Customer.id === updatedCustomer.id
    );
    if (index !== -1) {
      const updatedCustomers = [...Customers];
      updatedCustomers[index] = updatedCustomer;
      setCustomers(updatedCustomers);
      setSelectedCustomer(updatedCustomer);
    }
  };

  const openCart = (CustomerId) => {
    navigate(`/customers/${CustomerId}/cart`);
  };

  const columns = useMemo(
    () => [
      {
        Header: "id",
        accessor: "id",
      },
      {
        Header: "name",
        accessor: "name",
      },
      {
        Header: "phone",
        accessor: "phone",
      },
      {
        Header: "address",
        accessor: "address",
      },
      {
        Header: "balance",
        accessor: "balance",
      },
      {
        Header: "Actions",
        accessor: "actions",
        Cell: ({ row }) => (
          <div>
            <span onClick={() => openCustomer(row.id)}>
              <i className="far fa-edit action mr-2"></i>
            </span>
            <span
              onClick={() => handleDeleteCustomer(row.original.id)}
              style={{ marginLeft: "8px" }}
            >
              <i className="fas fa-trash action"></i>
            </span>
            <span
              onClick={() => openCart(row.original.id)}
              style={{ marginLeft: "8px" }}
            >
              <i class="fa-solid fa-cart-shopping action"></i>
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
      data: Customers,
    });
  const handleAddCustomer = () => {
    navigate("/customers/add");
  };
  return (
    <div className="list row">
      <div className="col-md-12 list">
        <h4>Customers List</h4>
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
          onClick={handleAddCustomer}
        >
          Add Customer
        </button>
      </div>

      {selectedCustomer && (
        <Customer
          Customer={selectedCustomer}
          handleUpdateCustomer={handleUpdateCustomer}
          handleDeleteCustomer={handleDeleteCustomer}
        />
      )}
    </div>
  );
};

export default CustomersList;
