/* 
Задание №1

Посчитайте количество и суммарные продажи чеков с шагом в 50 руб. (всех чеков 1-50 руб., всех
чеков 51-100 руб., всех чеков 101-150 руб. и т.д.):
*/

drop table The_Check;

CREATE TABLE The_Check
(
  Check_id varchar(255) NOT NULL PRIMARY KEY UNIQUE,
  Date date NOT NULL,
  Sales numeric NOT NULL
);

INSERT INTO The_Check (Check_id, Date, Sales) VALUES
('20211231083456X1230010', '2021-12-31', 458.56),
('20211023124512CV450462', '2021-10-23', 345.69),
('2022050615432912D29643', '2022-05-06', 43.25),
('20220610203921125R7431', '2022-06-10', 2789.01);

Select * from The_Check;

SELECT 
  CONCAT((FLOOR(Sales/50)*50)+1, '-', FLOOR(Sales/50+1)*50) AS Sales_Range,
  COUNT(*) AS Number_of_Checks,
  SUM(Sales) AS Total_Sales
FROM The_Check
GROUP BY Sales_Range;


/* 
Задание №2

Разделить пользователей на 3 типа: ушедшие, новые и LFL (в таблице все чеки 2021 и 2022 годов):
*/

drop table Client_Type;

CREATE TABLE Client_Type
(
  Client_id varchar(255) NOT NULL,
  Check_id varchar(255) NOT NULL PRIMARY KEY UNIQUE REFERENCES The_Check(Check_id),
  Date date NOT NULL
);
INSERT INTO Client_Type (Client_id, Check_id, Date) VALUES
('XC346631', '20211231083456X1230010', '2021-12-31'),
('AB534575', '20211023124512CV450462', '2021-10-23'),
('KK125882', '2022050615432912D29643', '2022-05-06'),
('KK125882', '20220610203921125R7431', '2022-06-10');
Select * from Client_Type;

---Представление по ушедшим клиентам---
CREATE VIEW Churned_Users AS
SELECT DISTINCT Client_id
FROM Client_Type
WHERE Client_id NOT IN (SELECT Client_id FROM Client_Type WHERE EXTRACT(YEAR FROM Date) = 2022);
SELECT * FROM Churned_Users;

---Представление по новым клиентам---
CREATE VIEW New_Users AS
SELECT DISTINCT Client_id
FROM Client_Type
WHERE Client_id NOT IN (SELECT Client_id FROM Client_Type WHERE EXTRACT(YEAR FROM Date) = 2021);
SELECT * FROM New_Users;

---Представление по LFL клиентам---
CREATE VIEW LFL_Users AS
SELECT DISTINCT Client_id
FROM Client_Type
WHERE Client_id IN (SELECT Client_id FROM Client_Type WHERE EXTRACT(YEAR FROM Date) = 2021)
  AND Client_id IN (SELECT Client_id FROM Client_Type WHERE EXTRACT(YEAR FROM Date) = 2022);
SELECT * FROM LFL_Users;

-----------------------------------------------------------------------------------------------------

drop table warehouses;

CREATE TABLE warehouses
(
  whs_id int NOT NULL PRIMARY KEY UNIQUE,
  frmt int NOT NULL,
  frmt_name varchar(255) NOT NULL
);


drop table transactions;

CREATE TABLE transactions
(
  trn_id int NOT NULL PRIMARY KEY UNIQUE,
  acc_id int NOT NULL,
  whs_id int NOT NULL REFERENCES warehouses(whs_id),
  trn_date timestamp NOT NULL,
  total numeric NOT NULL
);


drop table products;

CREATE TABLE products
(
  trn_id int NOT NULL REFERENCES transactions(trn_id),
  art_id int NOT NULL PRIMARY KEY UNIQUE,
  qnty numeric NOT NULL,
  value numeric NOT NULL
);

/* 
Задание №3

Для каждого клиента выведете магазин, в котором он совершил первую покупку, и ее дату;
*/

SELECT acc_id, whs_id, MIN(trn_date) AS first_purchase_date
FROM transactions
GROUP BY acc_id, whs_id;

/* 
Задание №4

Выведите список клиентов, которые соответствуют всем условиям:

1. После совершения покупки 8 недель подряд не посещали магазины форматов home или super;
2. После совершения покупки 4 недели не посещали магазин формата discounter;
3. Оба посещения из п.1 и п.2 должны быть последними посещениями клиента в соответствующих сетях.
(Нужны те, у которых промежуток между ближайшими посещениями более 8 и 4 недель соответственно. У каждого
клиента могут быть свои даты начала и окончания паузы в посещении, не нужно привязывать всех к одной дате).
*/

SELECT acc_id
FROM (
  SELECT 
    acc_id, 
    MAX(trn_date) AS last_purchase_date,
    MAX(CASE WHEN frmt_name IN ('home', 'super') THEN trn_date END) AS last_home_super_date,
    MAX(CASE WHEN frmt_name = 'discounter' THEN trn_date END) AS last_discounter_date
  FROM transactions
  JOIN warehouses ON transactions.whs_id = warehouses.whs_id
  GROUP BY acc_id
) AS sub
WHERE 
  last_purchase_date < NOW() - INTERVAL '8 weeks' AND 
  (last_home_super_date IS NULL OR last_home_super_date < NOW() - INTERVAL '8 weeks') AND
  (last_discounter_date IS NULL OR last_discounter_date < NOW() - INTERVAL '4 weeks');

/* 
Задание №5

Вывести клиентов, которые за период с 01.01.2021 по 01.04.2021 совершили покупку от 800 рублей и при этом в
этой покупке есть три и более штук товаров из списка 5531, 5532, 5535.
*/

SELECT DISTINCT t.acc_id
FROM transactions t
JOIN products p ON t.trn_id = p.trn_id
WHERE t.trn_date BETWEEN '2021-01-01' AND '2021-04-01'
AND t.total > 800
AND p.art_id IN (5531, 5532, 5535)
GROUP BY t.acc_id
HAVING COUNT(DISTINCT p.art_id) >= 3;