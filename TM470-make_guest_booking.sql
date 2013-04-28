/* -------------------------------------------------------------- */
/* TM470:  Make Guest Booking                                     */
/* Author: Kevin Peat                                             */
/* Date:   23-Apr-2012                                            */
/* -------------------------------------------------------------- */

/* -------------------------------------------------------------- */
/* Function: get_guest_id()                                       */
/* Purpose:  Checks to see if a guest making a booking is already */
/*           known to the system and if so just returns the guest */
/*           id. Otherwise a new guest record is created and the  */
/*           id for record that is returned                       */
/* -------------------------------------------------------------- */
/* Arguments:                                                     */
/*    v_guest_title = Guest title                                 */
/*    v_guest_first_name = Guest first name                       */
/*    v_guest_last_name = Guest last name                         */
/*    v_guest_premise = Guest house number or name                */
/*    v_guest_company = Guest company name                        */
/*    v_guest_thoroughfare = Guest street name                    */
/*    v_guest_locality_name = Guest town/city name                */
/*    v_guest_administrative_area = Guest county/state name       */
/*    v_guest_postal_code = Guest postal code                     */
/*    v_guest_country = Guest country name                        */
/*    v_guest_phone1 = Guest phone number                         */
/*    v_guest_email = Guest email address                         */
/* Example usage:                                                 */
/*    SELECT get_guest_id('Mr.','John','Smith','25',Null,         */
/*       'Some Road','Exeter','Devon','XX1 XX99','UK',            */
/*       '1234546','sdsd@sdsd.com');                              */
/* -------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION get_guest_id(v_guest_title text,
		v_guest_first_name text, v_guest_last_name text,
		v_guest_premise text, v_guest_company text,
		v_guest_thoroughfare text, v_guest_locality_name text,
		v_guest_administrative_area text, v_guest_postal_code text,
		v_guest_country text, v_guest_phone1 text,
		v_guest_email text) RETURNS integer AS $$
		
	DECLARE
		v_guests_row RECORD;
		v_id_val INTEGER; 
	BEGIN

		/* Check to see if guest already exists */
		FOR v_guests_row IN
			SELECT	g.id
			FROM 		guest g
			WHERE 	g.title = v_guest_title
			AND		g.last_name = v_guest_last_name
			AND		g.company = v_guest_company
			AND		g.premise = v_guest_premise
			AND		g.postal_code = v_guest_postal_code LOOP

			/* Guest already exists so return id */
			RETURN v_guests_row.id;

		END LOOP;

		/* Guest not found so insert a new record and get id */
		INSERT INTO guest(title, first_name, last_name, premise,
			company, thoroughfare, locality_name, administrative_area,
			postal_code, country, phone1, email)
		SELECT	v_guest_title,
					v_guest_first_name,
					v_guest_last_name,
					v_guest_premise,
					v_guest_company,
					v_guest_thoroughfare,
					v_guest_locality_name,
					v_guest_administrative_area,
					v_guest_postal_code,
					v_guest_country,
					v_guest_phone1,
					v_guest_email
		RETURNING id INTO v_id_val;

		RETURN v_id_val;

	END;

$$ LANGUAGE plpgsql;

/* -------------------------------------------------------------- */
/* Function: make_guest_booking()                                 */
/* Purpose:  Create a new guest booking. Information about the    */
/*           guest is passed in as arguments. Details about the   */
/*           rooms to be booked are stored in a temporary table   */
/*           before this function is called and accessed by the   */
/*           function when making the booking. Returns booking id */
/* -------------------------------------------------------------- */
/* Arguments:                                                     */
/*    v_bb_ref = Bed and breakfast reference where staying        */
/*    v_booking_type = Booking type required                      */
/*    v_booking_date = Booking date                               */
/*    v_arrive = Arrival date                                     */
/*    v_depart = Departure date                                   */
/*    v_referrer = Booking referrer name                          */
/*    v_notes = Booking notes                                     */
/*    v_guest_title = Guest title                                 */
/*    v_guest_first_name = Guest first name                       */
/*    v_guest_last_name = Guest last name                         */
/*    v_guest_premise = Guest house number or name                */
/*    v_guest_company = Guest company name                        */
/*    v_guest_thoroughfare = Guest street name                    */
/*    v_guest_locality_name = Guest town/city name                */
/*    v_guest_administrative_area = Guest county/state name       */
/*    v_guest_postal_code = Guest postal code                     */
/*    v_guest_country = Guest country name                        */
/*    v_guest_phone1 = Guest phone number                         */
/*    v_guest_email = Guest email address                         */
/* Example usage:                                                 */
/*    SELECT make_guest_booking('BB1', 'Bed and Breakfast',       */
/*       '2012-04-01', '2012-07-01', '2012-07-05', 'Unknown',     */
/*       'Mr.','John','Smith','25', Null, Some Road','Exeter',      */
/*       'Devon','XX1 XX99','UK', '1234546','sdsd@sdsd.com');     */
/* -------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION make_guest_booking(v_bb_ref text,
		v_booking_type text, v_booking_date date, 
		v_arrive date, v_depart date, v_referrer text, 
		v_guest_title text, v_guest_first_name text,
		v_guest_last_name text, v_guest_premise text,
		v_guest_company text, v_guest_thoroughfare text,
		v_guest_locality_name text, v_guest_administrative_area text,
		v_guest_postal_code text, v_guest_country text,
		v_guest_phone1 text, v_guest_email text) RETURNS integer AS $$
		
	DECLARE
		v_guest_id INTEGER; 
		v_booking_id INTEGER;
		v_booking_row RECORD;
		
	BEGIN
		/* Get guest id if guest is already known to system or add  */
		/* a new guest record and get the id for that */
		SELECT get_guest_id(v_guest_title,
			v_guest_first_name, v_guest_last_name, v_guest_premise,
			v_guest_company, v_guest_thoroughfare, v_guest_locality_name,
			v_guest_administrative_area, v_guest_postal_code,
			v_guest_country, v_guest_phone1, v_guest_email)
		INTO v_guest_id;
		
		/* Master booking record */
		/* All new bookings are created as 'Provisional' */
		INSERT INTO booking(guest, status, booking_type, referrer,
			booking_date, arrival_date, departure_date)
		SELECT	v_guest_id,
					'Provisional',
					v_booking_type,
					v_referrer,
					v_booking_date,
					v_arrive, 
					v_depart
		RETURNING id INTO v_booking_id;

		/* Booked room record(s) */
		FOR v_booking_row IN
			SELECT	*
			FROM		tmp_booking LOOP

			/* Create a booked room for each row in temp table */
			INSERT INTO booked_room(booking_id, bb_ref, room, adults,
				children, babies, cots_reqd, cost)
			SELECT	v_booking_id,
						v_bb_ref,
						v_booking_row.room_name,
						v_booking_row.adults,
						v_booking_row.children,
						v_booking_row.babies,
						v_booking_row.cots_reqd,
						v_booking_row.cost;

		END LOOP;

		RETURN v_booking_id;

	END;

$$ LANGUAGE plpgsql;



/* -------------------------------------------------------------- */
/* Function: run_make_guest_booking()                            */
/* Purpose:  Ad-hoc function required to run make_guest_booking() */
/*           to simulate what would be done by the front-end      */
/*           application in normal circumstances. Returns booking */
/*           reference if successful                              */
/* -------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION run_make_guest_booking() RETURNS integer AS $$
		
	DECLARE
		/* Simulated booking, common information */
		v_bb_ref TEXT := 'BB1';
		v_booking_type TEXT := 'Bed and Breakfast';
		v_booking_date DATE := '2012-04-01';
		v_arrive DATE := '2012-07-20';
		v_depart DATE := '2012-07-25';
		v_referrer TEXT := 'Unknown';
		v_guest_title TEXT := 'Mr.';
		v_guest_first_name TEXT := 'John';
		v_guest_last_name TEXT := 'Smith';
		v_guest_premise TEXT := '34';
		v_guest_company TEXT := '';
		v_guest_thoroughfare TEXT := 'A Street';
		v_guest_locality_name TEXT := 'A Town';
		v_guest_administrative_area TEXT := 'A County';
		v_guest_postal_code TEXT := 'AA11 1AA';
		v_guest_country TEXT := 'United Kingdom';
		v_guest_phone1 TEXT := '01234 567890';
		v_guest_email TEXT := 'john@smith.xyx';
		v_booking_id INTEGER;

	BEGIN
		/* A user of the web application would enter details of the */
		/* dates they want to stay, the type of booking required    */
		/* eg. B&B, and for each room required they would enter the */
		/* number of adults, children and babies to be accommodated */
		/* The front-end application would then check the database  */
		/* using the check_room_availability() function to see if   */
		/* the required types of room are available and the costs   */
		/* for those rooms. If the user was happy with the offered  */
		/* rooms they would select those they wish to book, enter   */
		/* their personal details and confirm they want to make a   */
		/* booking.                                                 */

		/* Create temporary table to store booking details */
		CREATE TEMP TABLE tmp_booking (
			room_name CHARACTER VARYING(20),
			adults GUESTS,
			children GUESTS,
			babies GUESTS,
			cots_reqd INTEGER,
			cost DOUBLE PRECISION) ON COMMIT DROP;

		/* Rooms to be booked */
		INSERT INTO tmp_booking (room_name, adults, children, babies, cots_reqd, cost)
		VALUES('Room 1', 2, 0, 0, 0, 330), ('Room 2', 2, 0, 0, 0, 280), ('Room 3', 1, 0, 0, 0, 150);

		/* Create booking */
		SELECT make_guest_booking(v_bb_ref,
				v_booking_type, v_booking_date, v_arrive, v_depart, 
				v_referrer, v_guest_title, v_guest_first_name,
				v_guest_last_name, v_guest_premise, v_guest_company, 
				v_guest_thoroughfare, v_guest_locality_name, 
				v_guest_administrative_area, v_guest_postal_code, 
				v_guest_country, v_guest_phone1, v_guest_email)
		INTO v_booking_id;

		RETURN v_booking_id;

	END;

$$ LANGUAGE plpgsql;

/* -------------------------------------------------------------- */
/* Function: run_make_guest_booking2()                            */
/* Purpose:  Ad-hoc function required to run make_guest_booking() */
/*           to simulate what would be done by the front-end      */
/*           application in normal circumstances. Returns booking */
/*           reference if successful                              */
/* -------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION run_make_guest_booking2() RETURNS integer AS $$
		
	DECLARE
		/* Simulated booking, common information */
		v_bb_ref TEXT := 'BB1';
		v_booking_type TEXT := 'Bed and Breakfast';
		v_booking_date DATE := '2012-04-01';
		v_arrive DATE := '2012-07-23';
		v_depart DATE := '2012-07-27';
		v_referrer TEXT := 'Unknown';
		v_guest_title TEXT := 'Mr.';
		v_guest_first_name TEXT := 'David';
		v_guest_last_name TEXT := 'Davis';
		v_guest_premise TEXT := '12';
		v_guest_company TEXT := '';
		v_guest_thoroughfare TEXT := 'My Street';
		v_guest_locality_name TEXT := 'My Town';
		v_guest_administrative_area TEXT := 'My County';
		v_guest_postal_code TEXT := 'XX11 1XX';
		v_guest_country TEXT := 'United Kingdom';
		v_guest_phone1 TEXT := '01234 567890';
		v_guest_email TEXT := 'david@davis.xyx';
		v_booking_id INTEGER;

	BEGIN
		/* A user of the web application would enter details of the */
		/* dates they want to stay, the type of booking required    */
		/* eg. B&B, and for each room required they would enter the */
		/* number of adults, children and babies to be accommodated */
		/* The front-end application would then check the database  */
		/* using the check_room_availability() function to see if   */
		/* the required types of room are available and the costs   */
		/* for those rooms. If the user was happy with the offered  */
		/* rooms they would select those they wish to book, enter   */
		/* their personal details and confirm they want to make a   */
		/* booking.                                                 */

		/* Create temporary table to store booking details */
		CREATE TEMP TABLE tmp_booking (
			room_name CHARACTER VARYING(20),
			adults GUESTS,
			children GUESTS,
			babies GUESTS,
			cots_reqd INTEGER,
			cost DOUBLE PRECISION) ON COMMIT DROP;

		/* Rooms to be booked */
		INSERT INTO tmp_booking (room_name, adults, children, babies, cots_reqd, cost)
		VALUES('Room 4', 1, 0, 0, 0, 150), ('Room 5', 1, 0, 0, 0, 150);

		/* Create booking */
		SELECT make_guest_booking(v_bb_ref,
				v_booking_type, v_booking_date, v_arrive, v_depart, 
				v_referrer, v_guest_title, v_guest_first_name,
				v_guest_last_name, v_guest_premise, v_guest_company, 
				v_guest_thoroughfare, v_guest_locality_name, 
				v_guest_administrative_area, v_guest_postal_code, 
				v_guest_country, v_guest_phone1, v_guest_email)
		INTO v_booking_id;

		RETURN v_booking_id;

	END;

$$ LANGUAGE plpgsql;





