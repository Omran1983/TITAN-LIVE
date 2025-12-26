import React, { useState, useEffect } from 'react';
import { initialDeliveries, DELIVERY_STATUS, getClientNames, filterByClient, filterByStatus, calculateTotal, calculateInvoiceTotal } from './deliveryData';
import './App.css';

function App() {
  const [deliveries, setDeliveries] = useState(initialDeliveries);
  const [clients, setClients] = useState([]);
  const [selectedClient, setSelectedClient] = useState('All');
  const [selectedStatus, setSelectedStatus] = useState('All');
  const [filteredDeliveries, setFilteredDeliveries] = useState(initialDeliveries);

  // Initialize clients list
  useEffect(() => {
    setClients(getClientNames(deliveries));
  }, [deliveries]);

  // Filter deliveries based on selected client and status
  useEffect(() => {
    let result = deliveries;
    
    if (selectedClient !== 'All') {
      result = filterByClient(result, selectedClient);
    }
    
    if (selectedStatus !== 'All') {
      result = filterByStatus(result, selectedStatus);
    }
    
    setFilteredDeliveries(result);
  }, [selectedClient, selectedStatus, deliveries]);

  // Handle status change for a delivery
  const handleStatusChange = (id, newStatus) => {
    setDeliveries(prevDeliveries => 
      prevDeliveries.map(delivery => 
        delivery.id === id ? { ...delivery, status: newStatus } : delivery
      )
    );
  };

  return (
    <div className="App">
      <header className="App-header">
        <h1>Delivery Invoicing App</h1>
        <div className="filters">
          <div className="filter-group">
            <label htmlFor="client-filter">Filter by Client: </label>
            <select 
              id="client-filter"
              value={selectedClient} 
              onChange={(e) => setSelectedClient(e.target.value)}
            >
              <option value="All">All Clients</option>
              {clients.map(client => (
                <option key={client} value={client}>{client}</option>
              ))}
            </select>
          </div>
          
          <div className="filter-group">
            <label htmlFor="status-filter">Filter by Status: </label>
            <select 
              id="status-filter"
              value={selectedStatus} 
              onChange={(e) => setSelectedStatus(e.target.value)}
            >
              <option value="All">All Statuses</option>
              <option value={DELIVERY_STATUS.PENDING}>{DELIVERY_STATUS.PENDING}</option>
              <option value={DELIVERY_STATUS.COMPLETED}>{DELIVERY_STATUS.COMPLETED}</option>
              <option value={DELIVERY_STATUS.CANCELLED}>{DELIVERY_STATUS.CANCELLED}</option>
            </select>
          </div>
        </div>
        
        <div className="invoice-container">
          <h2>
            {selectedClient === 'All' ? 'All Deliveries' : `${selectedClient}'s Deliveries`}
          </h2>
          
          <table className="deliveries-table">
            <thead>
              <tr>
                <th>Client</th>
                <th>Item</th>
                <th>Quantity</th>
                <th>Price</th>
                <th>Total</th>
                <th>Status</th>
                <th>Date</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {filteredDeliveries.map(delivery => (
                <tr key={delivery.id}>
                  <td>{delivery.clientName}</td>
                  <td>{delivery.itemName}</td>
                  <td>{delivery.quantity}</td>
                  <td>${delivery.price.toFixed(2)}</td>
                  <td>${calculateTotal(delivery.quantity, delivery.price).toFixed(2)}</td>
                  <td className={`status ${delivery.status.toLowerCase()}`}>
                    {delivery.status}
                  </td>
                  <td>{delivery.date}</td>
                  <td>
                    <select 
                      value={delivery.status} 
                      onChange={(e) => handleStatusChange(delivery.id, e.target.value)}
                    >
                      <option value={DELIVERY_STATUS.PENDING}>{DELIVERY_STATUS.PENDING}</option>
                      <option value={DELIVERY_STATUS.COMPLETED}>{DELIVERY_STATUS.COMPLETED}</option>
                      <option value={DELIVERY_STATUS.CANCELLED}>{DELIVERY_STATUS.CANCELLED}</option>
                    </select>
                  </td>
                </tr>
              ))}
            </tbody>
            <tfoot>
              <tr>
                <td colSpan="4"><strong>Invoice Total:</strong></td>
                <td colSpan="4">
                  <strong>${calculateInvoiceTotal(filteredDeliveries).toFixed(2)}</strong>
                </td>
              </tr>
            </tfoot>
          </table>
        </div>
      </header>
    </div>
  );
}

export default App;