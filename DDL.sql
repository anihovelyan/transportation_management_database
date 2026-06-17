DROP TABLE IF EXISTS Assignment;
DROP TABLE IF EXISTS Payment;
DROP TABLE IF EXISTS Boarding;
DROP TABLE IF EXISTS Ticket;
DROP TABLE IF EXISTS Trip;
DROP TABLE IF EXISTS Route_stop;
DROP TABLE IF EXISTS Passenger;
DROP TABLE IF EXISTS Schedule;
DROP TABLE IF EXISTS Route;
DROP TABLE IF EXISTS Vehicle;
DROP TABLE IF EXISTS Driver;
DROP TABLE IF EXISTS Station;

CREATE TABLE Station(
	station_id INTEGER PRIMARY KEY,
	zone VARCHAR(50),
	station_name VARCHAR(100)
);

CREATE TABLE Driver(
	driver_id INTEGER PRIMARY KEY,
	name VARCHAR(50),
	license_number VARCHAR(30)
);

CREATE TABLE Vehicle(
	vehicle_id INTEGER PRIMARY KEY,
	capacity INTEGER NOT NULL,
	type VARCHAR(20)
);

CREATE TABLE Route(
	route_id INTEGER PRIMARY KEY,
	name VARCHAR(50),
	starting_point VARCHAR(100),
	end_point VARCHAR(100)
);

CREATE TABLE Schedule(
	schedule_id INTEGER PRIMARY KEY,
	arrival_time TIMESTAMP,
	departure_time TIMESTAMP
);

CREATE TABLE Passenger(
	passenger_id INTEGER PRIMARY KEY,
	name VARCHAR(50) NOT NULL,
	phone VARCHAR(30),
	email VARCHAR(100)
);

CREATE TABLE Trip(
	trip_id INTEGER PRIMARY KEY,
	status VARCHAR(20),
	trip_date DATE NOT NULL,
	actual_departure_time TIMESTAMP,
	actual_arrival_time TIMESTAMP,
	current_passenger_count INTEGER DEFAULT 0,

	schedule_id INTEGER NOT NULL,
	route_id INTEGER NOT NULL,
	vehicle_id INTEGER NOT NULL,

	FOREIGN KEY (schedule_id) REFERENCES Schedule(schedule_id) ON DELETE RESTRICT,
	FOREIGN KEY (route_id) REFERENCES Route(route_id) ON DELETE RESTRICT,
	FOREIGN KEY (vehicle_id) REFERENCES Vehicle(vehicle_id) ON DELETE RESTRICT
);

CREATE TABLE Ticket(
	ticket_id INTEGER PRIMARY KEY,
	price DECIMAL(10,2) NOT NULL,
	ticket_type VARCHAR(30),
	passenger_id INTEGER NOT NULL,
	trip_id INTEGER NOT NULL,
	CHECK (price > 0),
	FOREIGN KEY (passenger_id) REFERENCES Passenger(passenger_id) ON DELETE CASCADE,
	FOREIGN KEY (trip_id) REFERENCES Trip(trip_id) ON DELETE CASCADE
);

CREATE TABLE Payment(
	payment_id INTEGER PRIMARY KEY,
	amount DECIMAL(10,2) NOT NULL,
	payment_method VARCHAR(30),
	payment_time TIMESTAMP,
	ticket_id INTEGER UNIQUE NOT NULL,
	FOREIGN KEY (ticket_id) REFERENCES Ticket(ticket_id)
);

CREATE TABLE Boarding(
	boarding_id INTEGER PRIMARY KEY,
	boarding_time TIMESTAMP,
	boarding_status VARCHAR(20),
	seat_number VARCHAR(10),
	is_validated BOOLEAN DEFAULT FALSE,
	platform VARCHAR(20),

	ticket_id INTEGER NOT NULL,
	station_id INTEGER NOT NULL,
	trip_id INTEGER NOT NULL,

	FOREIGN KEY (ticket_id) REFERENCES Ticket(ticket_id) ON DELETE CASCADE,
	FOREIGN KEY (station_id) REFERENCES Station(station_id) ON DELETE RESTRICT,
	FOREIGN KEY (trip_id) REFERENCES Trip(trip_id) ON DELETE CASCADE
);

CREATE TABLE Route_stop(
	route_id INTEGER NOT NULL,
	stop_number INTEGER NOT NULL,
	station_id INTEGER NOT NULL,
	planned_arrival_time TIMESTAMP,
	planned_departure_time TIMESTAMP,

	PRIMARY KEY (route_id, stop_number),
	FOREIGN KEY (route_id) REFERENCES Route(route_id),
	FOREIGN KEY (station_id) REFERENCES Station(station_id)
);

CREATE TABLE Assignment(
	assignment_id INTEGER PRIMARY KEY,
	start_time TIMESTAMP,
	end_time TIMESTAMP,
	CHECK (start_time < end_time),

	driver_id INTEGER NOT NULL,
	vehicle_id INTEGER NOT NULL,
	trip_id INTEGER NOT NULL,

	FOREIGN KEY (driver_id) REFERENCES Driver(driver_id),
	FOREIGN KEY (vehicle_id) REFERENCES Vehicle(vehicle_id),
	FOREIGN KEY (trip_id) REFERENCES Trip(trip_id)
);