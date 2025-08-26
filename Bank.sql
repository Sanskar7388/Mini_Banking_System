-- Mini Banking System Project
-- Author: Sanskar Sengar
-- Description: SQL project simulating a small banking system with customers, accounts, and transactions.

-- Step 1: Create Database
CREATE DATABASE MiniBank;
USE MiniBank;

-- Step 2: Create Tables
CREATE TABLE Customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(15),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Accounts (
    account_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT,
    account_type ENUM('Savings', 'Current') NOT NULL,
    balance DECIMAL(12,2) DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id)
);

CREATE TABLE Transactions (
    transaction_id INT AUTO_INCREMENT PRIMARY KEY,
    from_account INT,
    to_account INT,
    amount DECIMAL(12,2) NOT NULL CHECK (amount > 0),
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (from_account) REFERENCES Accounts(account_id),
    FOREIGN KEY (to_account) REFERENCES Accounts(account_id)
);

-- Step 3: Insert Sample Data
INSERT INTO Customers (name, email, phone) VALUES
('Alice Johnson', 'alice@example.com', '9876543210'),
('Bob Smith', 'bob@example.com', '9876501234'),
('Charlie Brown', 'charlie@example.com', '9876512345');

INSERT INTO Accounts (customer_id, account_type, balance) VALUES
(1, 'Savings', 5000.00),
(2, 'Current', 10000.00),
(3, 'Savings', 7000.00);

-- Step 4: Create Stored Procedure for Money Transfer
DELIMITER //
CREATE PROCEDURE TransferMoney(
    IN sender INT,
    IN receiver INT,
    IN amt DECIMAL(12,2)
)
BEGIN
    DECLARE senderBalance DECIMAL(12,2);

    SELECT balance INTO senderBalance FROM Accounts WHERE account_id = sender;

    IF senderBalance >= amt THEN
        -- Deduct from sender
        UPDATE Accounts SET balance = balance - amt WHERE account_id = sender;
        -- Add to receiver
        UPDATE Accounts SET balance = balance + amt WHERE account_id = receiver;
        -- Record transaction
        INSERT INTO Transactions (from_account, to_account, amount)
        VALUES (sender, receiver, amt);
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient Balance';
    END IF;
END //
DELIMITER ;

-- Step 5: Create Trigger to Auto Log Large Transactions
DELIMITER //
CREATE TRIGGER LogLargeTransactions
AFTER INSERT ON Transactions
FOR EACH ROW
BEGIN
    IF NEW.amount > 5000 THEN
        INSERT INTO Transactions (from_account, to_account, amount)
        VALUES (NEW.from_account, NEW.to_account, 0.00); -- Dummy log row
    END IF;
END //
DELIMITER ;

-- Step 6: Create Views
CREATE VIEW TransactionView AS
SELECT t.transaction_id, c1.name AS Sender, c2.name AS Receiver, t.amount, t.transaction_date
FROM Transactions t
JOIN Accounts a1 ON t.from_account = a1.account_id
JOIN Accounts a2 ON t.to_account = a2.account_id
JOIN Customers c1 ON a1.customer_id = c1.customer_id
JOIN Customers c2 ON a2.customer_id = c2.customer_id;

-- Advanced Analytics Views
-- 1. Monthly spending per customer
CREATE VIEW MonthlySpending AS
SELECT c.name, MONTH(t.transaction_date) AS Month, SUM(t.amount) AS TotalSpent
FROM Transactions t
JOIN Accounts a ON t.from_account = a.account_id
JOIN Customers c ON a.customer_id = c.customer_id
GROUP BY c.name, MONTH(t.transaction_date);

-- 2. Fraud detection (suspicious high-value transfers)
CREATE VIEW SuspiciousTransactions AS
SELECT * FROM TransactionView
WHERE amount > 10000;

-- 3. Most active customers
CREATE VIEW TopCustomers AS
SELECT c.name, COUNT(t.transaction_id) AS TransactionCount
FROM Transactions t
JOIN Accounts a ON t.from_account = a.account_id
JOIN Customers c ON a.customer_id = c.customer_id
GROUP BY c.name
ORDER BY TransactionCount DESC
LIMIT 5;

-- Step 7: Test Transfers
CALL TransferMoney(1, 2, 2000.00);
CALL TransferMoney(2, 3, 3000.00);
CALL TransferMoney(3, 1, 8000.00); -- Will fail if insufficient balance

-- Step 8: Check Views
SELECT * FROM TransactionView;
SELECT * FROM MonthlySpending;
SELECT * FROM SuspiciousTransactions;
SELECT * FROM TopCustomers;
