// Delivery data model and utility functions

// Define delivery statuses
export const DELIVERY_STATUS = {
  PENDING: 'Pending',
  COMPLETED: 'Completed',
  CANCELLED: 'Cancelled'
};

// Sample initial delivery data
export const initialDeliveries = [
  {
    id: 1,
    clientName: 'John Smith',
    itemName: 'Electronics Package',
    quantity: 2,
    price: 150.00,
    status: DELIVERY_STATUS.PENDING,
    date: '2025-10-01'
  },
  {
    id: 2,
    clientName: 'ABC Company',
    itemName: 'Office Supplies',
    quantity: 5,
    price: 75.50,
    status: DELIVERY_STATUS.COMPLETED,
    date: '2025-09-28'
  },
  {
    id: 3,
    clientName: 'John Smith',
    itemName: 'Books',
    quantity: 3,
    price: 45.99,
    status: DELIVERY_STATUS.CANCELLED,
    date: '2025-09-30'
  },
  {
    id: 4,
    clientName: 'XYZ Corporation',
    itemName: 'Industrial Equipment',
    quantity: 1,
    price: 500.00,
    status: DELIVERY_STATUS.PENDING,
    date: '2025-10-02'
  },
  {
    id: 5,
    clientName: 'ABC Company',
    itemName: 'Software Licenses',
    quantity: 10,
    price: 25.00,
    status: DELIVERY_STATUS.COMPLETED,
    date: '2025-09-25'
  }
];

// Function to calculate total amount for a delivery
export const calculateTotal = (quantity, price) => {
  return quantity * price;
};

// Function to get unique client names
export const getClientNames = (deliveries) => {
  const clientNames = deliveries.map(delivery => delivery.clientName);
  return [...new Set(clientNames)];
};

// Function to filter deliveries by client
export const filterByClient = (deliveries, clientName) => {
  return deliveries.filter(delivery => delivery.clientName === clientName);
};

// Function to filter deliveries by status
export const filterByStatus = (deliveries, status) => {
  return deliveries.filter(delivery => delivery.status === status);
};

// Function to calculate invoice total for a client
export const calculateInvoiceTotal = (deliveries) => {
  return deliveries.reduce((total, delivery) => {
    return total + calculateTotal(delivery.quantity, delivery.price);
  }, 0);
};