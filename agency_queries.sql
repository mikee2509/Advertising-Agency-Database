---QUERIES---
--Full address information of all employees
SELECT E.first_name || ' ' || E.last_name AS NAME, A.street_address, A.postal_code, A.city, A.country
FROM employee E JOIN address A ON E.address_id = A.ID
ORDER BY E.last_name, E.first_name;


--List employees along with their current assignments
SELECT E.first_name || ' ' || E.last_name AS employee, A.contract_id, T.DESCRIPTION FROM employee E 
JOIN assignment A ON E.pesel = A.employee_pesel
JOIN task T ON A.task_id = T.ID
WHERE A.status = 'in progress'
ORDER BY E.last_name, E.first_name, A.contract_id;


--List emplyees along with the number of their assignemnts - show those who have the lowest number first
SELECT E.first_name || ' ' || E.last_name AS employee, COUNT(E.first_name || ' ' || E.last_name) AS assignments 
FROM assignment A JOIN employee E ON A.employee_pesel = E.pesel
WHERE status = 'in progress' 
GROUP BY E.first_name || ' ' || E.last_name ORDER BY 2;


--List emplyees along with the number of hours of assigned tasks - show those who have the lowest number first
SELECT E.first_name || ' ' || E.last_name AS Employee, SUM(T.estimated_duration) AS Hours FROM task T 
JOIN assignment A ON A.task_id = T.ID
JOIN employee E ON A.employee_pesel = E.pesel
WHERE status = 'in progress'
GROUP BY E.first_name || ' ' || E.last_name
ORDER BY 2;


--Show the number of onging contracts
SELECT COUNT(*) AS ongoing_contracts FROM contract WHERE start_date < sysdate AND end_date > sysdate;


--List ongoing contracts along with client name, contract value, number of tasks involved and number of man-hours required
SELECT C.ID AS Contract, A.NAME AS Client, C.total_value AS Value, x.tasks AS Tasks, y.TIME AS "MAN-HOURS"
FROM contract C 
JOIN client A 
    ON C.client_id = A.ID
JOIN (SELECT contract_id, COUNT(contract_id) AS tasks FROM assignment GROUP BY contract_id) x 
    ON C.ID = x.contract_id
JOIN (SELECT A.contract_id AS ID, SUM(T.estimated_duration) AS time FROM assignment A
        JOIN task T ON A.task_id = T.ID GROUP BY A.contract_id) y
    ON C.ID = y.ID
WHERE C.start_date < sysdate AND C.end_date > sysdate
ORDER BY 1;


--List all contracts with overdue invoices - show client's name and phone number, payable sum and total contract value
SELECT x.contract_id, C.NAME AS CLIENT, C.phone_number, x.due_sum, A.total_value FROM contract A
JOIN CLIENT C
    ON A.client_id = C.ID
JOIN (SELECT contract_id, SUM(VALUE) AS due_sum FROM invoice 
        WHERE payment_deadline < sysdate AND payment_date IS NULL 
        GROUP BY contract_id) x
    ON A.ID = x.contract_id
ORDER BY 1;


--List all contracts with only one paid invoice
SELECT contract_id FROM invoice
WHERE payment_date IS NOT NULL
GROUP BY contract_id
HAVING COUNT(contract_id) = 1
ORDER BY 1;


--List all due invoices with the number of days remaining for payment
SELECT ID AS invoice, contract_id, VALUE, floor(payment_deadline-sysdate) AS "DAYS REMAINING" FROM invoice
WHERE payment_date IS NULL AND payment_deadline > sysdate
ORDER BY 1;


---INDEXES---
EXECUTE DBMS_STATS.GATHER_TABLE_STATS ('msieczko','address');
EXECUTE DBMS_STATS.GATHER_TABLE_STATS ('msieczko','assignment');
EXECUTE DBMS_STATS.GATHER_TABLE_STATS ('msieczko','client');
EXECUTE DBMS_STATS.GATHER_TABLE_STATS ('msieczko','contract');
EXECUTE DBMS_STATS.GATHER_TABLE_STATS ('msieczko','employee');
EXECUTE DBMS_STATS.GATHER_TABLE_STATS ('msieczko','invoice');
EXECUTE DBMS_STATS.GATHER_TABLE_STATS ('msieczko','task');

alter index invoice_pk visible;
--alter index invoice_pk invisible;
explain plan for
select * from invoice where id between 1 and 556; --up to id=556 oracle optimizer uses index
select * from table (dbms_xplan.display);


/* invoice_idx1 -  invoice(ID, contract_id) *
 * invoice_idx2 -  invoice(contract_id, ID) */
alter index invoice_idx1 visible;
alter index invoice_idx2 visible;
--alter index invoice_idx1 invisible;
--alter index invoice_idx2 invisible;
explain plan for
select * from invoice where id between 1 and 600 and contract_id = 10;
select * from table (dbms_xplan.display);

--Full table scan hint
explain plan for
select /*+ full(invoice) */ * from invoice where id between 1 and 600 and contract_id = 10;
select * from table (dbms_xplan.display);
