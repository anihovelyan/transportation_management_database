DROP TRIGGER IF EXISTS check_driver ON Assignment;
DROP TRIGGER IF EXISTS check_vehicle ON Assignment;
DROP TRIGGER IF EXISTS check_time ON Assignment;
DROP TRIGGER IF EXISTS trg_validate_payment_amount ON Payment;
DROP TRIGGER IF EXISTS trg_auto_stop ON Route_stop;
DROP TRIGGER IF EXISTS trg_check_times ON Route_stop;
DROP TRIGGER IF EXISTS trg_no_duplicate_stops ON Route_stop;
DROP TRIGGER IF EXISTS trg_boarding_after_insert ON Boarding;
DROP TRIGGER IF EXISTS trg_check_passenger_exists ON Ticket;


DROP FUNCTION IF EXISTS trg_check_time(); 
DROP FUNCTION IF EXISTS boarding_after_insert(); 
DROP FUNCTION IF EXISTS auto_increment_stop();
DROP FUNCTION IF EXISTS validate_route_timing();
DROP FUNCTION IF EXISTS check_duplicate_stops(); 
DROP FUNCTION IF EXISTS check_passenger_exists(); 
DROP FUNCTION IF EXISTS validate_payment_amount();

ALTER TABLE Assignment DROP CONSTRAINT IF EXISTS no_driver_overlap;
ALTER TABLE Assignment DROP CONSTRAINT IF EXISTS no_vehicle_overlap;

/*INDEXES*/

/* TRIP / BOARDING / ROUTE / ASSIGNMENT */

CREATE INDEX idx_trip_schedule ON Trip(schedule_id);
CREATE INDEX idx_boarding_trip ON Boarding(trip_id);
CREATE INDEX idx_boarding_station ON Boarding(station_id);
CREATE INDEX idx_routestop_route_order ON Route_stop(route_id, stop_number);

CREATE INDEX idx_assignment_driver_time
ON Assignment(driver_id, start_time, end_time);

CREATE INDEX idx_assignment_vehicle_time
ON Assignment(vehicle_id, start_time, end_time);

/* PASSENGER / TICKET / PAYMENT */

CREATE INDEX idx_ticket_passenger ON Ticket(passenger_id);
CREATE INDEX idx_ticket_type ON Ticket(ticket_type);

CREATE INDEX idx_payment_ticket ON Payment(ticket_id);
CREATE INDEX idx_payment_method ON Payment(payment_method);
CREATE INDEX idx_payment_time ON Payment(payment_time);

ALTER TABLE Payment
ADD CONSTRAINT unique_ticket_payment UNIQUE(ticket_id);

/*FUCNTIONS*/

/*create_trip_from_schedule*/
CREATE OR REPLACE FUNCTION create_trip_from_schedule(
    p_schedule_id INT,
    p_route_id INT,
    p_vehicle_id INT,
    p_trip_date DATE
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO Trip(schedule_id, route_id, vehicle_id, trip_date, status)
    VALUES (p_schedule_id, p_route_id, p_vehicle_id, p_trip_date, 'Scheduled');
END;
$$ LANGUAGE plpgsql;

/*Auto stop_number*/
CREATE OR REPLACE FUNCTION auto_increment_stop()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.stop_number IS NULL THEN
        SELECT COALESCE(MAX(stop_number), 0) + 1
        INTO NEW.stop_number
        FROM Route_stop
        WHERE route_id = NEW.route_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

/*Validate arrival/departure*/
CREATE OR REPLACE FUNCTION validate_route_timing()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.planned_departure_time <= NEW.planned_arrival_time THEN
    RAISE EXCEPTION 'Departure must be after arrival';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

/*Prevent duplicate consecutive stations*/
CREATE OR REPLACE FUNCTION check_duplicate_stops()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM Route_stop
        WHERE route_id = NEW.route_id
          AND station_id = NEW.station_id
    ) THEN
        RAISE EXCEPTION 'Duplicate station in route';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

/*Check trip capacity after boarding*/
CREATE OR REPLACE FUNCTION boarding_after_insert()
RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT current_passenger_count FROM Trip WHERE trip_id = NEW.trip_id)
       >= (SELECT capacity FROM Vehicle v
           JOIN Trip t ON t.vehicle_id = v.vehicle_id
           WHERE t.trip_id = NEW.trip_id) THEN
        RAISE EXCEPTION 'Trip is full';
    END IF;

    UPDATE Trip
    SET current_passenger_count = current_passenger_count + 1
    WHERE trip_id = NEW.trip_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

/*Driver time conflict*/
CREATE OR REPLACE FUNCTION trg_check_driver()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM Assignment
        WHERE driver_id = NEW.driver_id
          AND NEW.start_time < end_time
          AND NEW.end_time > start_time
    ) THEN
        RAISE EXCEPTION 'Driver is already assigned in this time interval';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

/*Vehicle time conflict*/
CREATE OR REPLACE FUNCTION trg_check_vehicle()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM Assignment
        WHERE vehicle_id = NEW.vehicle_id
          AND NEW.start_time < end_time
          AND NEW.end_time > start_time
    ) THEN
        RAISE EXCEPTION 'Vehicle is already assigned in this time interval';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

/*Start time < End time*/
CREATE OR REPLACE FUNCTION validate_assignment_time()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.start_time >= NEW.end_time THEN
        RAISE EXCEPTION 'Start time must be before end time';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


/* Ensures a ticket cannot be created for a non-existing passenger */
CREATE OR REPLACE FUNCTION check_passenger_exists()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM Passenger
        WHERE passenger_id = NEW.passenger_id
    ) THEN
        RAISE EXCEPTION 'Passenger does not exist';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

/* Ensures the payment amount exactly matches the ticket price */
CREATE OR REPLACE FUNCTION validate_payment_amount()
RETURNS TRIGGER AS $$
DECLARE ticket_price NUMERIC;
BEGIN
    SELECT price INTO ticket_price
    FROM Ticket
    WHERE ticket_id = NEW.ticket_id;

    IF NEW.amount <> ticket_price THEN
        RAISE EXCEPTION 'Payment must equal ticket price';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


/*TRIGGERS*/

/* Route_stop */
CREATE TRIGGER trg_auto_stop
BEFORE INSERT ON Route_stop
FOR EACH ROW
EXECUTE FUNCTION auto_increment_stop();

CREATE TRIGGER trg_check_times
BEFORE INSERT OR UPDATE ON Route_stop
FOR EACH ROW
EXECUTE FUNCTION validate_route_timing();

CREATE TRIGGER trg_no_duplicate_stops
BEFORE INSERT ON Route_stop
FOR EACH ROW
EXECUTE FUNCTION check_duplicate_stops();

/* Boarding */
CREATE TRIGGER trg_boarding_after_insert
AFTER INSERT ON Boarding
FOR EACH ROW
EXECUTE FUNCTION boarding_after_insert();

/* Assignment */
CREATE TRIGGER check_driver
BEFORE INSERT OR UPDATE ON Assignment
FOR EACH ROW
EXECUTE FUNCTION trg_check_driver();

CREATE TRIGGER check_vehicle
BEFORE INSERT OR UPDATE ON Assignment
FOR EACH ROW
EXECUTE FUNCTION trg_check_vehicle();

CREATE TRIGGER check_time
BEFORE INSERT OR UPDATE ON Assignment
FOR EACH ROW
EXECUTE FUNCTION validate_assignment_time();

/* Ticket */
CREATE TRIGGER trg_check_passenger_exists
BEFORE INSERT ON Ticket
FOR EACH ROW
EXECUTE FUNCTION check_passenger_exists();

/* Payment */
CREATE TRIGGER trg_validate_payment_amount
BEFORE INSERT ON Payment
FOR EACH ROW
EXECUTE FUNCTION validate_payment_amount();

