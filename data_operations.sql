/*
1. Full purchase history
*/
SELECT
    p.passenger_id,
    p.name,
    p.email,
    t.ticket_id,
    t.ticket_type,
    t.price,
    pay.payment_id,
    pay.amount,
    pay.payment_method,
    pay.payment_time
FROM Passenger p
JOIN Ticket t
ON p.passenger_id = t.passenger_id
JOIN Payment pay
ON t.ticket_id = pay.ticket_id
ORDER BY p.passenger_id, pay.payment_time DESC;


/*
2. Passengers with no purchased tickets
*/
SELECT
    p.passenger_id,
    p.name,
    p.email
FROM Passenger p
LEFT JOIN Ticket t
ON p.passenger_id = t.passenger_id
WHERE t.ticket_id IS NULL;

/*
3. Revenue by ticket type
*/
SELECT
    t.ticket_type,
    COUNT(t.ticket_id) AS tickets_sold,
    SUM(pay.amount) AS total_revenue
FROM Ticket t
JOIN Payment pay
ON t.ticket_id = pay.ticket_id
GROUP BY t.ticket_type
ORDER BY total_revenue DESC;


/*
4. Revenue by payment method
*/
SELECT
    payment_method,
    COUNT(payment_id) AS total_payments,
    SUM(amount) AS total_revenue
FROM Payment
GROUP BY payment_method
ORDER BY total_revenue DESC;


/*
5. Frequent passengers above average ticket purchases
*/
SELECT
    p.passenger_id,
    p.name,
    COUNT(t.ticket_id) AS ticket_count
FROM Passenger p
JOIN Ticket t
ON p.passenger_id = t.passenger_id
GROUP BY p.passenger_id, p.name
HAVING COUNT(t.ticket_id) > (
    SELECT AVG(ticket_count)
    FROM (
        SELECT COUNT(ticket_id) AS ticket_count
        FROM Ticket
        GROUP BY passenger_id
    ) sub
)
ORDER BY ticket_count DESC;


/*
6. Most recent payment for each passenger
*/
SELECT
    p.passenger_id,
    p.name,
    pay.payment_id,
    pay.amount,
    pay.payment_method,
    pay.payment_time
FROM Passenger p
JOIN Ticket t
ON p.passenger_id = t.passenger_id
JOIN Payment pay
ON t.ticket_id = pay.ticket_id
WHERE pay.payment_time = (
    SELECT MAX(pay2.payment_time)
    FROM Ticket t2
    JOIN Payment pay2
    ON t2.ticket_id = pay2.ticket_id
    WHERE t2.passenger_id = p.passenger_id
);


/*
7. Ticket types purchased more than average
*/
SELECT
    ticket_type,
    COUNT(ticket_id) AS purchase_count
FROM Ticket
GROUP BY ticket_type
HAVING COUNT(ticket_id) > (
    SELECT AVG(type_count)
    FROM (
        SELECT COUNT(ticket_id) AS type_count
        FROM Ticket
        GROUP BY ticket_type
    ) sub
)
ORDER BY purchase_count DESC;


/*
8. Daily payment revenue
*/
SELECT
    DATE(payment_time) AS payment_date,
    COUNT(payment_id) AS total_payments,
    SUM(amount) AS daily_revenue
FROM Payment
GROUP BY DATE(payment_time)
ORDER BY payment_date;


/*
9. Passengers who used a specific payment method
*/
SELECT
    p.passenger_id,
    p.name,
    p.email
FROM Passenger p
WHERE EXISTS (
    SELECT 1
    FROM Ticket t
    JOIN Payment pay
    ON t.ticket_id = pay.ticket_id
    WHERE t.passenger_id = p.passenger_id
      AND pay.payment_method = 'Card'
);

/*
10.Basic trip overview
*/
SELECT 
    t.trip_date,
    t.status,
    t.schedule_id,
    t.actual_departure_time,
    t.actual_arrival_time,
    s.arrival_time,
    s.departure_time
FROM Trip t
JOIN Schedule s 
ON t.schedule_id = s.schedule_id;

/*
11.Most used schedules
*/
SELECT s.schedule_id, COUNT(trip_id) AS trip_count
FROM Schedule s 
LEFT JOIN Trip t 
ON s.schedule_id = t.schedule_id
GROUP BY s.schedule_id
ORDER BY trip_count DESC;

/*
12.Trips by status
*/
SELECT status,
COUNT(*) AS trip_count
FROM Trip
GROUP BY status
ORDER BY trip_count DESC;

/* 
13.Delayed trips
*/
SELECT t.trip_id,t.actual_departure_time,s.departure_time
FROM Schedule s
JOIN Trip t ON t.schedule_id=s.schedule_id
WHERE t.actual_departure_time>s.departure_time;

/*
14.Trips with no passengers
*/

/*No tickets*/
SELECT t.trip_id
FROM Trip t
LEFT JOIN Ticket tk 
ON t.trip_id = tk.trip_id
WHERE tk.trip_id IS NULL
ORDER BY t.trip_id desc;

/*No boarding*/
SELECT t.trip_id
FROM Trip t
LEFT JOIN Boarding b 
ON t.trip_id = b.trip_id
GROUP BY t.trip_id
HAVING COUNT(b.boarding_id) = 0
ORDER BY t.trip_id desc;

/*
15.Passengers per trip
*/
SELECT t.trip_id, COUNT(b.boarding_id) AS boarding_count
FROM Trip t
LEFT JOIN Boarding b 
ON t.trip_id = b.trip_id
GROUP BY t.trip_id
ORDER BY t.trip_id;

/*
16.Most popular trips
*/
SELECT t.trip_id,COUNT(b.boarding_id) AS boarding_count
FROM Trip t
LEFT JOIN Boarding b 
ON t.trip_id = b.trip_id
GROUP BY t.trip_id
ORDER BY boarding_count DESC;

/*
17.High-performing trips
*/
SELECT t.trip_id,COUNT(tk.passenger_id) AS passenger_count
FROM Trip t
LEFT JOIN Ticket tk 
ON t.trip_id = tk.trip_id
GROUP BY t.trip_id
HAVING COUNT(tk.passenger_id) > (
    SELECT AVG(passenger_count)
    FROM (
        SELECT COUNT(tk2.passenger_id) AS passenger_count
        FROM Trip t2
        LEFT JOIN Ticket tk2 
            ON t2.trip_id = tk2.trip_id
        GROUP BY t2.trip_id
    ) sub
)
ORDER BY passenger_count DESC;

/*
18.Daily workload
*/
SELECT trip_date,COUNT(*) AS trip_count
FROM Trip
GROUP BY trip_date
ORDER BY trip_date;

/*
19.Busiest day
*/
SELECT trip_date,COUNT(*) AS trip_count
FROM Trip
GROUP BY trip_date
ORDER BY trip_count DESC
LIMIT 1;

/*
20.Schedules that generate most passengers
*/
SELECT s.schedule_id,COUNT(b.boarding_id) AS passenger_count
FROM Schedule s
LEFT JOIN Trip t 
ON s.schedule_id = t.schedule_id
LEFT JOIN Boarding b 
ON t.trip_id = b.trip_id
GROUP BY s.schedule_id
ORDER BY passenger_count DESC;

/*
21.Route structure
*/
SELECT 
r.route_id,r.name,
rs.stop_number,rs.planned_arrival_time,rs.planned_departure_time,
s.station_name
FROM Route r 
JOIN Route_stop rs 
ON r.route_id=rs.route_id
JOIN Station s 
ON rs.station_id=s.station_id
ORDER BY r.route_id, rs.stop_number;
   
/*
22.Most important stations
*/
SELECT s.station_id,s.station_name, COUNT(DISTINCT rs.route_id) AS important_stat
FROM Station s 
JOIN Route_stop rs
ON s.station_id=rs.station_id
GROUP BY s.station_id,s.station_name
ORDER BY important_stat DESC;

/*
23.Complex routes
*/

SELECT r.route_id,r.name,
COUNT(rs.stop_number) AS total_stops
FROM Route r
JOIN Route_stop rs ON r.route_id = rs.route_id
GROUP BY r.route_id, r.name
HAVING COUNT(rs.stop_number) > (
    SELECT AVG(stop_count)
    FROM (
        SELECT COUNT(*) AS stop_count
        FROM Route_stop
        GROUP BY route_id
    ) AS avg_table
)
ORDER BY total_stops DESC;

/*
24.Station usage coverage
*/
SELECT 
    s.station_id,
    s.station_name,
    COUNT(DISTINCT rs.route_id) AS routes_used_in,
    (COUNT(DISTINCT rs.route_id) * 100.0 / total_routes.total_count) AS coverage_percentage
FROM Station s
JOIN Route_stop rs ON s.station_id = rs.station_id
CROSS JOIN (
    SELECT COUNT(*) AS total_count
    FROM Route
) total_routes
GROUP BY s.station_id, s.station_name, total_routes.total_count
ORDER BY coverage_percentage DESC;

/*
25.Most connected stations 
*/

SELECT 
    s.station_name,
    COUNT(DISTINCT rs.route_id) AS connected_routes
FROM Station s
JOIN Route_stop rs ON s.station_id = rs.station_id
GROUP BY s.station_name
HAVING COUNT(DISTINCT rs.route_id) > 2
ORDER BY connected_routes DESC;

/*
26.ROUTE GEOGRAPHIC BREADTH

*/
SELECT 
    name, 
    starting_point, 
    end_point, 
    (SELECT COUNT(*) FROM Route_stop WHERE route_id = r.route_id) AS total_stops
FROM Route r
ORDER BY total_stops DESC;

/*
27.Zone density report
*/
SELECT 
    zone, 
    COUNT(station_id) AS total_stations,
    COUNT(DISTINCT station_name) AS unique_station_names
FROM Station
GROUP BY zone
ORDER BY total_stations DESC;

/*
28.Station dwell time analysis
*/
SELECT 
    r.name AS route_name,
    s.station_name,
    rs.stop_number,
    (rs.planned_departure_time - rs.planned_arrival_time) AS planned_dwell_time
FROM Route_stop rs
JOIN Route r ON rs.route_id = r.route_id
JOIN Station s ON rs.station_id = s.station_id
WHERE (rs.planned_departure_time - rs.planned_arrival_time) > INTERVAL '0 minutes'
ORDER BY planned_dwell_time DESC;

/*
29.Empty route integrity check
*/
SELECT r.route_id, r.name
FROM Route r
LEFT JOIN Route_stop rs ON r.route_id = rs.route_id
WHERE rs.route_id IS NULL;

/*
30.Station attribute validation
*/
SELECT station_id, station_name
FROM Station
WHERE zone IS NULL OR zone = '';

/*
31.Drivers above average workload (CTE)
*/
WITH driver_counts AS (
    SELECT driver_id, COUNT(*) AS total
    FROM Assignment
    GROUP BY driver_id
),
avg_val AS (
    SELECT AVG(total) AS avg_count FROM driver_counts
)
SELECT d.driver_id, d.name, dc.total
FROM driver_counts dc
JOIN avg_val av ON dc.total > av.avg_count
JOIN Driver d ON d.driver_id = dc.driver_id;


/*
32.Vehicle utilization
*/
SELECT v.vehicle_id, v.type,
       SUM(a.end_time - a.start_time) AS total_usage
FROM Vehicle v
JOIN Assignment a ON v.vehicle_id = a.vehicle_id
GROUP BY v.vehicle_id, v.type;

/*
33.Available drivers
*/
SELECT *
FROM Driver d
WHERE NOT EXISTS (
    SELECT 1 FROM Assignment a
    WHERE a.driver_id = d.driver_id
      AND CURRENT_TIMESTAMP BETWEEN a.start_time AND a.end_time
);

/*
34.Available vehicles
*/
SELECT *
FROM Vehicle v
WHERE NOT EXISTS (
    SELECT 1 FROM Assignment a
    WHERE a.vehicle_id = v.vehicle_id
      AND CURRENT_TIMESTAMP BETWEEN a.start_time AND a.end_time
);

/*
35.Full assignment details
*/
SELECT a.assignment_id, d.name, v.type,
       a.start_time, a.end_time
FROM Assignment a
JOIN Driver d ON a.driver_id = d.driver_id
JOIN Vehicle v ON a.vehicle_id = v.vehicle_id;

/*
36.Least used vehicles
*/
SELECT v.vehicle_id, v.type, COUNT(a.assignment_id) AS usage_count
FROM Vehicle v
LEFT JOIN Assignment a ON v.vehicle_id = a.vehicle_id
GROUP BY v.vehicle_id, v.type
ORDER BY usage_count ASC, v.vehicle_id
LIMIT 10;

/*
37.Most recent assignment
*/
SELECT *
FROM Assignment
WHERE end_time = (SELECT MAX(end_time) FROM Assignment);

/*
38.Idle drivers
*/
SELECT d.driver_id, d.name,
       CURRENT_TIMESTAMP - MAX(a.end_time) AS idle_time
FROM Driver d
LEFT JOIN Assignment a ON d.driver_id = a.driver_id
GROUP BY d.driver_id, d.name;

/*
39.Daily workload
*/
SELECT DATE(start_time) AS day, COUNT(*) AS total_assignments
FROM Assignment
GROUP BY DATE(start_time)
ORDER BY day;

