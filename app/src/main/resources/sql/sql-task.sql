-- 1.	Вывести к каждому самолету класс обслуживания и количество мест этого класса
SELECT aircrafts.aircraft_code,
       aircrafts.model,
       seats.fare_conditions,
       COUNT(seats.seat_no) as seat_count
FROM aircrafts
         JOIN
     seats ON aircrafts.aircraft_code = seats.aircraft_code
GROUP BY aircrafts.aircraft_code,
         aircrafts.model,
         seats.fare_conditions;

-- 2.	Найти 3 самых вместительных самолета (модель + кол-во мест)

SELECT aircrafts.model,
       COUNT(seats.seat_no) as seat_count
FROM aircrafts
         JOIN
     seats ON aircrafts.aircraft_code = seats.aircraft_code
GROUP BY aircrafts.model
ORDER BY seat_count DESC
LIMIT 3;

-- 3.	Найти все рейсы, которые задерживались более 2 часов

SELECT flights_v.flight_no,
       flights_v.scheduled_departure,
       flights_v.actual_departure,
       flights_v.scheduled_arrival,
       flights_v.actual_arrival
FROM flights_v
WHERE EXTRACT(EPOCH FROM (flights_v.actual_departure - flights_v.scheduled_departure)) > 2 * 60 * 60;
-- или
SELECT flights_v.flight_no,
       flights_v.scheduled_departure,
       flights_v.actual_departure,
       flights_v.scheduled_arrival,
       flights_v.actual_arrival
FROM flights_v
WHERE flights_v.actual_departure - flights_v.scheduled_departure > INTERVAL '2 hours';

-- 4.	Найти последние 10 билетов, купленные в бизнес-классе (fare_conditions = 'Business'), с указанием имени пассажира и контактных данных
SELECT tickets.passenger_name,
       tickets.contact_data,
       ticket_flights.fare_conditions
FROM tickets
         JOIN
     ticket_flights ON tickets.ticket_no = ticket_flights.ticket_no
WHERE ticket_flights.fare_conditions = 'Business'
ORDER BY tickets.book_ref DESC
LIMIT 10;

-- 5.	Найти все рейсы, у которых нет забронированных мест в бизнес-классе (fare_conditions = 'Business')
SELECT flights_v.flight_no,
       flights_v.departure_airport,
       flights_v.arrival_airport
FROM flights_v
WHERE flights_v.flight_id NOT IN (SELECT ticket_flights.flight_id
                                  FROM ticket_flights
                                  WHERE ticket_flights.fare_conditions = 'Business');
-- 6.	Получить список аэропортов (airport_name) и городов (city), в которых есть рейсы с задержкой
SELECT airports.airport_name,
       airports.city
FROM airports
WHERE airports.airport_code IN (SELECT flights_v.departure_airport
                                FROM flights_v
                                WHERE flights_v.actual_departure - flights_v.scheduled_departure > INTERVAL '0 hours')
   OR airports.airport_code IN (SELECT flights_v.arrival_airport
                                FROM flights_v
                                WHERE flights_v.actual_arrival - flights_v.scheduled_arrival > INTERVAL '0 hours');

-- 7.	Получить список аэропортов (airport_name) и количество рейсов, вылетающих из каждого аэропорта, отсортированный по убыванию количества рейсов
SELECT airports.airport_name,
       COUNT(flights_v.flight_no) as flight_count
FROM airports
         JOIN
     flights_v ON airports.airport_code = flights_v.departure_airport
GROUP BY airports.airport_name
ORDER BY flight_count DESC;

-- 8.	Найти все рейсы, у которых запланированное время прибытия (scheduled_arrival) было изменено и новое время прибытия (actual_arrival) не совпадает с запланированным
SELECT flights_v.flight_no,
       flights_v.scheduled_departure,
       flights_v.scheduled_arrival,
       flights_v.actual_departure,
       flights_v.actual_arrival
FROM flights_v
WHERE flights_v.actual_arrival IS NOT NULL
  AND flights_v.actual_arrival <> flights_v.scheduled_arrival;

-- 9.	Вывести код, модель самолета и места не эконом класса для самолета "Аэробус A321-200" с сортировкой по местам
SELECT aircrafts.aircraft_code,
       aircrafts.model,
       seats.seat_no
FROM aircrafts
         JOIN
     seats ON aircrafts.aircraft_code = seats.aircraft_code
WHERE aircrafts.model = 'Аэробус A321-200'
  AND seats.fare_conditions <> 'Economy'
ORDER BY seats.seat_no;
-- 10.	Вывести города, в которых больше 1 аэропорта (код аэропорта, аэропорт, город)
SELECT airports.airport_code,
       airports.airport_name,
       airports.city
FROM airports
WHERE airports.city IN (SELECT city
                        FROM airports
                        GROUP BY city
                        HAVING COUNT(airport_code) > 1);

-- 11.	Найти пассажиров, у которых суммарная стоимость бронирований превышает среднюю сумму всех бронирований
SELECT tickets.passenger_id,
       tickets.passenger_name,
       SUM(bookings.total_amount) as total_booking_amount
FROM tickets
         JOIN
     bookings ON tickets.book_ref = bookings.book_ref
GROUP BY tickets.passenger_id,
         tickets.passenger_name
HAVING SUM(bookings.total_amount) > (SELECT AVG(total_amount)
                                     FROM bookings);
-- 12.	Найти ближайший вылетающий рейс из Екатеринбурга в Москву, на который еще не завершилась регистрация
SELECT flights_v.flight_no,
       flights_v.scheduled_departure,
       flights_v.scheduled_departure_local,
       flights_v.status
FROM flights_v
WHERE flights_v.departure_city = 'Екатеринбург'
  AND flights_v.arrival_city = 'Москва'
  AND flights_v.status NOT IN ('Departed', 'Arrived', 'Cancelled')
  AND flights_v.scheduled_departure > bookings.now()
ORDER BY flights_v.scheduled_departure
LIMIT 1;

-- 13.	Вывести самый дешевый и дорогой билет и стоимость (в одном результирующем ответе)
SELECT 'Cheapest Ticket'          AS Type,
       MIN(ticket_flights.amount) AS Cost
FROM ticket_flights

UNION ALL

SELECT 'Most Expensive Ticket'    AS Type,
       MAX(ticket_flights.amount) AS Cost
FROM ticket_flights;
-- 14.	Написать DDL таблицы Customers, должны быть поля id, firstName, LastName, email, phone. Добавить ограничения на поля (constraints)
CREATE TABLE Customers
(
    id        SERIAL PRIMARY KEY,
    firstName VARCHAR(50)         NOT NULL,
    lastName  VARCHAR(50)         NOT NULL,
    email     VARCHAR(255) UNIQUE NOT NULL,
    phone     VARCHAR(15) UNIQUE  NOT NULL
);
-- 15.	Написать DDL таблицы Orders, должен быть id, customerId, quantity. Должен быть внешний ключ на таблицу customers + constraints
CREATE TABLE Orders
(
    id         SERIAL PRIMARY KEY,
    customerId INTEGER NOT NULL,
    quantity   INTEGER NOT NULL CHECK (quantity > 0),
    FOREIGN KEY (customerId) REFERENCES Customers (id)
);
-- 16.	Написать 5 insert в эти таблицы
INSERT INTO Customers (firstName, lastName, email, phone)
VALUES ('Иван', 'Иванов', 'ivanov@example.com', '1234567890'),
       ('Петр', 'Петров', 'petrov@example.com', '0987654321'),
       ('Сергей', 'Сергеев', 'sergeev@example.com', '1122334455'),
       ('Анна', 'Аннова', 'annova@example.com', '2233445566'),
       ('Мария', 'Мариева', 'marieva@example.com', '3344556677');

INSERT INTO Orders (customerId, quantity)
VALUES (1, 5),
       (2, 3),
       (3, 1),
       (4, 2),
       (5, 4);
--                       17.	Удалить таблицы
DROP TABLE IF EXISTS Orders;
DROP TABLE IF EXISTS Customers;
