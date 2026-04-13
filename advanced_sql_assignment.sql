-- ADVANCE SQL Assignment

-- Q1. What is a Common Table Expression (CTE), and how does it improve SQL query readability?
/*Answer:
A Common Table Expression (CTE) is a temporary named result set defined using the WITH clause.
It improves readability by breaking complex queries into smaller logical parts, reducing nested subqueries,
and making SQL easier to understand and maintain
*/

WITH Example_CTE AS (
    SELECT Product_ID, Product_Name, Price
    FROM Products
)
SELECT *
FROM Example_CTE;


-- Q2. Why are some views updatable while others are read-only? Explain with an example.
/*Answer
Why some views are updatable--
A view is usually updatable if:
It selects from only one base table.
It does not use GROUP BY, DISTINCT, or aggregate functions like SUM, COUNT, AVG, etc.
It includes all mandatory columns 
(e.g., NOT NULL columns without defaults), and there is a 1:1 mapping between a row in the view and a row in the base table.
When these conditions hold, an UPDATE on the view becomes an UPDATE on the underlying table, and the database can safely apply the change.

Why some views are read‑only--
A view becomes read‑only when:
It uses joins between multiple tables It uses aggregations (GROUP BY, COUNT, SUM, etc.).
It uses DISTINCT, computed expressions, or window functions.
In these cases, there is no 1:1 mapping between the view rows and the underlying rows, 
so the DBMS cannot decide how a change on the view should affect the base tables. 
Therefore it blocks INSERT, UPDATE, or DELETE on that view.
*/
-- 1. Updatable view (simple filter on one table)
CREATE TABLE employees (
    id INT PRIMARY KEY,
    name VARCHAR(50),
    salary DECIMAL(10,2),
    dept_id INT
);

CREATE VIEW it_employees AS
SELECT id, name, salary
FROM employees
WHERE dept_id = 1;

UPDATE it_employees
SET salary = 70000
WHERE id = 101;

-- 2. Read only view (join + aggregation)

CREATE VIEW dept_stats AS
SELECT d.dept_name,
       COUNT(e.id)    AS emp_count,
       AVG(e.salary)  AS avg_salary
FROM employees e
JOIN departments d ON e.dept_id = d.id
GROUP BY d.dept_name;


-- Q3. What advantages do stored procedures offer compared to writing raw SQL queries repeatedly?
/*Answer:
Stored procedures offer several advantages over writing the same raw SQL queries repeatedly in application code. They centralize SQL logic, 
improve performance, enhance security, and make maintenance easier. 
### 1. Better performance  
Stored procedures are **compiled once** and their execution plan is cached by the database, so subsequent calls are faster than parsing the same raw SQL each time. 
They also reduce network traffic because you send a short `EXEC procedure_name` call instead of a long SQL string every time. 

### 2. Reusability and modular code  
A stored procedure can be **called from many places** (different apps, scripts, or reports) without duplicating SQL code.
This avoids copy‑paste errors and keeps logic consistent across the system. 

### 3. Easier maintenance and changes  
If a business rule or query needs to change, you can **update the stored procedure once in the database**, 
and all applications using it automatically get the new logic—no need to recompile or redeploy every application. 

### 4. Improved security  
Stored procedures allow **fine‑grained access control**: you can give users permission to execute procedures but deny direct access to tables.
This reduces the risk of SQL injection because input is passed as parameters rather than concatenated into raw SQL strings. 

### 5. Centralized business logic  
Complex rules (like validation, multi‑step inserts, or calculations) can be **encapsulated inside procedures** in the database, 
so they are enforced in one place instead of scattered across application code.
This helps keep business logic consistent and easier for DBAs and developers to manage together.
 */

-- Q4. What is the purpose of triggers in a database? Mention one use case where a trigger is essential.
/* Answer
The purpose of a **trigger** in a database is to automatically execute a set of predefined actions 
(SQL statements or procedures) whenever a specific event occurs on a table or view, such as an `INSERT`, 
`UPDATE`, or `DELETE`.  Triggers are mainly used to enforce **data integrity**, maintain **consistency across related tables**, 
and automate **business rules or logging** without relying on application‑level code.
### One essential use case  
A common and essential use case for a trigger is **maintaining an audit log** of changes to sensitive data.  
For example, in an employee‑salary system, you can create a **`BEFORE UPDATE`** or **`AFTER UPDATE`** trigger on the
 `employees` table that automatically inserts a record into a `salary_audit` table whenever an employee’s salary is modified, 
 capturing the old salary, new salary, user ID, and timestamp. This ensures a reliable history of changes for compliance and security, 
 and you don’t need to duplicate this logging logic in every application‑level update statement
 */

-- Q5. Explain the need for data modelling and normalization when designing a database.
/* Answer:
Data modelling helps design the structure of a database by identifying entities,
attributes, and relationships.
Normalization reduces data redundancy, avoids insert/update/delete anomalies,
and improves data integrity.
Example structure after normalization:
*/

CREATE TABLE Categories (
    Category_ID INT PRIMARY KEY,
    Category_Name VARCHAR(50)
);

CREATE TABLE Normalized_Products (
    Product_ID INT PRIMARY KEY,
    Product_Name VARCHAR(100),
    Category_ID INT,
    Price DECIMAL(10,2),
    FOREIGN KEY (Category_ID) REFERENCES Categories(Category_ID)
);

-- Dataset (Use for Q6-Q9)

CREATE TABLE Products (
    ProductID INT PRIMARY KEY,
    ProductName VARCHAR(100),
    Category VARCHAR(50),
    Price DECIMAL(10,2)
);

INSERT INTO Products VALUES
(1, 'Keyboard', 'Electronics', 1200),
(2, 'Mouse', 'Electronics', 800),
(3, 'Chair', 'Furniture', 2500),
(4, 'Desk', 'Furniture', 5500);

CREATE TABLE Sales (
    SaleID INT PRIMARY KEY,
    ProductID INT,
    Quantity INT,
    SaleDate DATE,
    FOREIGN KEY (ProductID) REFERENCES Products (ProductID)
);

INSERT INTO Sales VALUES
(1, 1, 4, '2024-01-05'),
(2, 2, 10, '2024-01-06'),
(3, 3, 2, '2024-01-10'),
(4, 4, 1, '2024-01-11');

-- Q6. Write a CTE to calculate the total revenue for each product (Revenue = Price * Quantity), and return only products where revenue > 3000.
WITH ProductRevenue AS (
    SELECT 
        p.ProductID,
        p.ProductName,
        p.Price,
        SUM(s.Quantity) AS TotalQuantity,
        p.Price * SUM(s.Quantity) AS Revenue
    FROM Products p
    JOIN Sales s ON p.ProductID = s.ProductID
    GROUP BY p.ProductID, p.ProductName, p.Price
)
SELECT ProductID, Product_Name, Price, Total_Quantity, Revenue
FROM ProductRevenue
WHERE Revenue > 3000;


-- Q7. Create a view named vwCategorySummary that shows Category, TotalProducts, AveragePrice.
CREATE VIEW vw_Category_Summary AS
SELECT 
    Category,
    COUNT(*) AS Total_Products,
    AVG(Price) AS Average_Price
FROM Products
GROUP BY Category;


-- Q8. Create an updatable view containing ProductID, ProductName, and Price. Then update the price of ProductID=1 using the view.
CREATE VIEW vw_Product_Details AS
SELECT Product_ID, Product_Name, Price
FROM Products;

UPDATE vw_Product_Details
SET Price = 1300
WHERE Product_ID = 1;

-- Q9. Create a stored procedure that accepts a category name and returns all products belonging to that category.

DELIMITER //
CREATE PROCEDURE GetProductsByCategory(IN CategoryName VARCHAR(50))
BEGIN
    SELECT ProductID, ProductName, Category, Price
    FROM Products
    WHERE Category = CategoryName;
END //
DELIMITER ;

CALL GetProductsByCategory('Electronics');


/* Q10. Create an AFTER DELETE trigger on the Products table that archives deleted product rows into a new table ProductArchive.
The archive should store ProductID, ProductName, Category, Price, and DeletedAt timestamp.
*/

-- Create the archive table
CREATE TABLE ProductArchive (
    ProductID INT,
    ProductName VARCHAR(100),
    Category VARCHAR(50),
    Price DECIMAL(10,2),
    DeletedAt DATETIME
);

DELIMITER //

CREATE TRIGGER trg_ProductArchive
AFTER DELETE ON Products
FOR EACH ROW
BEGIN
    INSERT INTO ProductArchive (ProductID, ProductName, Category, Price, DeletedAt)
    VALUES (OLD.ProductID, OLD.ProductName, OLD.Category, OLD.Price, NOW());
END //

DELIMITER ;
