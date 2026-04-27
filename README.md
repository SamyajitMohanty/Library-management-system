# Library Management System — DBMS Mini Project

## Tech Stack
- **Frontend**: HTML, CSS, JavaScript (no frameworks)
- **Backend**: MySQL 8.0+
- **Connectivity**: PHP / Node.js / Python (any backend language to connect MySQL ↔ HTML)

---

## Database Setup

1. Open MySQL Workbench or terminal
2. Run the schema file:
   ```sql
   source schema.sql;
   ```
3. This creates:
   - Database: `library_db`
   - 5 tables: `members`, `books`, `categories`, `issued_books`, `fine_payments`
   - 2 views, 2 stored procedures, and sample data

---

## Tables

| Table | Description |
|-------|-------------|
| `members` | Registered library members |
| `books` | Book catalog with copy tracking |
| `categories` | Book categories |
| `issued_books` | Issue/return records with fines |
| `fine_payments` | Fine payment records |

---

## Features

| Feature | Description |
|---------|-------------|
| Add/Delete Books | Manage book catalog |
| Register Members | Add library members |
| Issue Book | Issue a book to a member with due date |
| Return Book | Return book, auto-calculates fine (₹5/day) |
| Overdue Tracking | Dashboard shows overdue books |
| Transaction History | Full history with filters |
| SQL Schema View | ER overview and stored procedure reference |

---

## Key SQL Concepts Used (for viva)

- **DDL**: CREATE TABLE, ALTER TABLE, DROP
- **DML**: INSERT, UPDATE, DELETE, SELECT
- **Constraints**: PRIMARY KEY, FOREIGN KEY, UNIQUE, NOT NULL, DEFAULT
- **ENUM**: status fields
- **Views**: `v_issued_books`, `v_book_availability`
- **Stored Procedures**: `issue_book()`, `return_book()`
- **Joins**: INNER JOIN across books, members, issued_books
- **Aggregate Functions**: SUM, COUNT, DATEDIFF
- **Subqueries & CASE WHEN**

---

## Fine Calculation Logic

```
Fine = (CURDATE() - due_date) × ₹5 per day
```
Only applied when `CURDATE() > due_date`.

---

## Folder Structure

```
library_management/
├── index.html     ← Frontend (open in browser)
├── schema.sql     ← MySQL database setup
└── README.md      ← This file
```

---

## For Full Stack Integration (optional)

To connect frontend to MySQL:
- Use **PHP** with `mysqli` or `PDO`
- Or **Python Flask** with `mysql-connector-python`
- Or **Node.js** with `mysql2` package

Replace the in-memory JS data in `index.html` with `fetch()` calls to your backend API.
