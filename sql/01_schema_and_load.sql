-- ============================================================
-- Retail SQL Business Case Study - Schema
-- ============================================================

CREATE DATABASE IF NOT EXISTS retail_case_study;
USE retail_case_study;

CREATE TABLE stores (
    StoreID   VARCHAR(10) PRIMARY KEY,
    StoreName VARCHAR(100),
    City      VARCHAR(50),
    Region    VARCHAR(50)
);

CREATE TABLE products (
    ProductID   VARCHAR(10) PRIMARY KEY,
    ProductName VARCHAR(100),
    Category    VARCHAR(50),
    UnitCost    DECIMAL(10,2),
    UnitPrice   DECIMAL(10,2)
);

CREATE TABLE customers (
    CustomerID   VARCHAR(10) PRIMARY KEY,
    CustomerName VARCHAR(100),
    City         VARCHAR(50),
    Segment      VARCHAR(50),
    JoinDate     DATE
);

CREATE TABLE employees (
    EmployeeID   VARCHAR(10) PRIMARY KEY,
    EmployeeName VARCHAR(100),
    StoreID      VARCHAR(10),
    Role         VARCHAR(50)
);

CREATE TABLE orders (
    OrderID     VARCHAR(20) PRIMARY KEY,
    OrderDate   DATE,
    CustomerID  VARCHAR(10),
    StoreID     VARCHAR(10),
    EmployeeID  VARCHAR(10),
    OrderStatus VARCHAR(20)
);

CREATE TABLE order_items (
    OrderItemID VARCHAR(20) PRIMARY KEY,
    OrderID     VARCHAR(20),
    ProductID   VARCHAR(10),
    Quantity    INT,
    UnitPrice   DECIMAL(10,2),
    Discount    DECIMAL(5,2),
    LineTotal   DECIMAL(12,2)
);

CREATE TABLE payments (
    PaymentID     VARCHAR(20) PRIMARY KEY,
    OrderID       VARCHAR(20),
    PaymentMethod VARCHAR(30),
    Amount        DECIMAL(12,2),
    PaymentDate   DATE
);

-- Import CSVs from data/ into matching tables:
-- stores, products, customers, employees, orders, order_items, payments
