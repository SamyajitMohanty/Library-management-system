-- ============================================
-- LIBRARY MANAGEMENT SYSTEM - MySQL Schema
-- ============================================

CREATE DATABASE IF NOT EXISTS library_db;
USE library_db;

-- 1. Members table
CREATE TABLE members (
    member_id     INT AUTO_INCREMENT PRIMARY KEY,
    name          VARCHAR(100) NOT NULL,
    email         VARCHAR(100) UNIQUE NOT NULL,
    phone         VARCHAR(15),
    address       TEXT,
    joined_date   DATE NOT NULL DEFAULT (CURRENT_DATE),
    status        ENUM('active', 'inactive', 'suspended') DEFAULT 'active'
);

-- 2. Categories table
CREATE TABLE categories (
    category_id   INT AUTO_INCREMENT PRIMARY KEY,
    name          VARCHAR(50) NOT NULL UNIQUE,
    description   TEXT
);

-- 3. Books table
CREATE TABLE books (
    book_id       INT AUTO_INCREMENT PRIMARY KEY,
    title         VARCHAR(200) NOT NULL,
    author        VARCHAR(100) NOT NULL,
    isbn          VARCHAR(20) UNIQUE,
    category_id   INT,
    publisher     VARCHAR(100),
    year          YEAR,
    total_copies  INT DEFAULT 1,
    available_copies INT DEFAULT 1,
    FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE SET NULL
);

-- 4. Issued Books table
CREATE TABLE issued_books (
    issue_id      INT AUTO_INCREMENT PRIMARY KEY,
    book_id       INT NOT NULL,
    member_id     INT NOT NULL,
    issue_date    DATE NOT NULL DEFAULT (CURRENT_DATE),
    due_date      DATE NOT NULL,
    return_date   DATE DEFAULT NULL,
    fine_amount   DECIMAL(6,2) DEFAULT 0.00,
    status        ENUM('issued', 'returned', 'overdue') DEFAULT 'issued',
    FOREIGN KEY (book_id)   REFERENCES books(book_id)   ON DELETE CASCADE,
    FOREIGN KEY (member_id) REFERENCES members(member_id) ON DELETE CASCADE
);

-- 5. Fine Payments table
CREATE TABLE fine_payments (
    payment_id    INT AUTO_INCREMENT PRIMARY KEY,
    issue_id      INT NOT NULL,
    amount_paid   DECIMAL(6,2) NOT NULL,
    payment_date  DATE DEFAULT (CURRENT_DATE),
    FOREIGN KEY (issue_id) REFERENCES issued_books(issue_id) ON DELETE CASCADE
);

-- ============================================
-- SAMPLE DATA
-- ============================================

INSERT INTO categories (name, description) VALUES
('Fiction',       'Novels and fictional stories'),
('Science',       'Science and technology books'),
('History',       'Historical accounts and biographies'),
('Mathematics',   'Math textbooks and references'),
('Computer Science', 'Programming and CS theory');

INSERT INTO books (title, author, isbn, category_id, publisher, year, total_copies, available_copies) VALUES
('The Alchemist',              'Paulo Coelho',       '978-0062315007', 1, 'HarperCollins', 1988, 3, 3),
('A Brief History of Time',    'Stephen Hawking',    '978-0553380163', 2, 'Bantam Books',  1988, 2, 2),
('Sapiens',                    'Yuval Noah Harari',  '978-0062316097', 3, 'Harper Perennial', 2015, 2, 2),
('Introduction to Algorithms', 'Cormen et al.',      '978-0262033848', 4, 'MIT Press',     2009, 4, 4),
('Clean Code',                 'Robert C. Martin',   '978-0132350884', 5, 'Prentice Hall', 2008, 3, 3),
('1984',                       'George Orwell',      '978-0451524935', 1, 'Signet Classic', 1949, 2, 2),
('The Great Gatsby',           'F. Scott Fitzgerald','978-0743273565', 1, 'Scribner',      1925, 2, 2),
('Cosmos',                     'Carl Sagan',         '978-0345539434', 2, 'Ballantine',    1980, 2, 2);

INSERT INTO members (name, email, phone, address, joined_date) VALUES
('Arjun Sharma',  'arjun.sharma@email.com',  '9876543210', '12 MG Road, Bengaluru',     '2024-01-15'),
('Priya Nair',    'priya.nair@email.com',    '9765432109', '45 Koramangala, Bengaluru',  '2024-02-20'),
('Rohan Mehta',   'rohan.mehta@email.com',   '9654321098', '8 Indiranagar, Bengaluru',   '2024-03-10'),
('Sneha Iyer',    'sneha.iyer@email.com',    '9543210987', '23 Jayanagar, Bengaluru',    '2024-04-05');

-- Issue some books
INSERT INTO issued_books (book_id, member_id, issue_date, due_date, status) VALUES
(1, 1, '2025-04-01', '2025-04-15', 'returned'),
(3, 2, '2025-04-10', '2025-04-24', 'issued'),
(5, 3, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 14 DAY), 'issued');

-- Update available copies after issues
UPDATE books SET available_copies = available_copies - 1 WHERE book_id IN (3, 5);

-- ============================================
-- USEFUL VIEWS
-- ============================================

-- View: Current issued books with member and book details
CREATE OR REPLACE VIEW v_issued_books AS
SELECT
    ib.issue_id,
    b.title        AS book_title,
    b.author,
    m.name         AS member_name,
    m.email,
    ib.issue_date,
    ib.due_date,
    ib.return_date,
    ib.fine_amount,
    ib.status,
    CASE
        WHEN ib.status = 'issued' AND ib.due_date < CURDATE()
        THEN DATEDIFF(CURDATE(), ib.due_date)
        ELSE 0
    END AS overdue_days
FROM issued_books ib
JOIN books   b ON ib.book_id   = b.book_id
JOIN members m ON ib.member_id = m.member_id;

-- View: Book availability summary
CREATE OR REPLACE VIEW v_book_availability AS
SELECT
    b.book_id, b.title, b.author, c.name AS category,
    b.total_copies, b.available_copies,
    (b.total_copies - b.available_copies) AS issued_copies
FROM books b
LEFT JOIN categories c ON b.category_id = c.category_id;

-- ============================================
-- STORED PROCEDURES
-- ============================================

DELIMITER //

-- Issue a book to a member
CREATE PROCEDURE issue_book(IN p_book_id INT, IN p_member_id INT, IN p_days INT)
BEGIN
    DECLARE avail INT;
    SELECT available_copies INTO avail FROM books WHERE book_id = p_book_id;
    IF avail > 0 THEN
        INSERT INTO issued_books (book_id, member_id, issue_date, due_date, status)
        VALUES (p_book_id, p_member_id, CURDATE(), DATE_ADD(CURDATE(), INTERVAL p_days DAY), 'issued');
        UPDATE books SET available_copies = available_copies - 1 WHERE book_id = p_book_id;
        SELECT 'Book issued successfully' AS message;
    ELSE
        SELECT 'No copies available' AS message;
    END IF;
END //

-- Return a book and calculate fine (₹5 per overdue day)
CREATE PROCEDURE return_book(IN p_issue_id INT)
BEGIN
    DECLARE v_due DATE;
    DECLARE v_book INT;
    DECLARE v_fine DECIMAL(6,2);
    SELECT due_date, book_id INTO v_due, v_book FROM issued_books WHERE issue_id = p_issue_id;
    SET v_fine = IF(CURDATE() > v_due, DATEDIFF(CURDATE(), v_due) * 5.00, 0);
    UPDATE issued_books
    SET return_date = CURDATE(), fine_amount = v_fine, status = 'returned'
    WHERE issue_id = p_issue_id;
    UPDATE books SET available_copies = available_copies + 1 WHERE book_id = v_book;
    SELECT CONCAT('Returned. Fine: ₹', v_fine) AS message;
END //

DELIMITER ;

-- ============================================
-- USEFUL QUERIES (for reference)
-- ============================================

-- All available books
-- SELECT * FROM v_book_availability WHERE available_copies > 0;

-- Overdue books
-- SELECT * FROM v_issued_books WHERE status = 'issued' AND due_date < CURDATE();

-- Member borrowing history
-- SELECT * FROM v_issued_books WHERE email = 'arjun.sharma@email.com';

-- Books by category
-- SELECT b.title, b.author, b.available_copies FROM books b JOIN categories c ON b.category_id = c.category_id WHERE c.name = 'Fiction';

-- Total fines collected
-- SELECT SUM(fine_amount) AS total_fines FROM issued_books WHERE status = 'returned';
