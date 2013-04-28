/* ------------------------------------------------------ */
/* TM470:  Postgresql Object Creation Script              */
/* Author: Kevin Peat                                     */
/* ------------------------------------------------------ */

DROP FUNCTION cancel_guest_booking(integer);
DROP FUNCTION check_room_availability(text, text, date, date, numeric, numeric, numeric);
DROP FUNCTION get_room_cost(text, text, text, date, date, numeric, numeric, numeric);
DROP FUNCTION housekeeping_report(text, date);
DROP FUNCTION run_make_guest_booking();
DROP FUNCTION make_guest_booking(text, text, date, date, date, text, text, text, text, text, text, text, text, text, text, text, text, text);
DROP FUNCTION get_guest_id(text, text, text, text, text, text, text, text, text, text, text, text);
DROP FUNCTION populate_tariff(text, date, date, numeric, numeric, numeric, numeric, numeric, numeric, numeric, numeric, numeric, numeric, numeric, numeric, numeric);
DROP FUNCTION populate_tariff_rows(text, text, text, date, numeric, numeric, numeric, numeric);
DROP VIEW unconfirmed_bookings;
DROP VIEW bandb_income;
DROP VIEW debtors;
DROP VIEW guest_bill_bandb;
DROP VIEW guest_bill_booking;
DROP VIEW guest_bill_rooms;
DROP VIEW guest_bill_charges;
DROP VIEW guest_bill_payments;
DROP VIEW guest_income;
DROP VIEW referrer_income;
DROP TABLE payment;
DROP TABLE room_charge;
DROP TABLE booked_room;
DROP TABLE booking;
DROP TABLE guest;
DROP TABLE referrer;
DROP TABLE staff;
DROP TABLE tariff;
DROP TABLE long_stay_discount;
DROP TABLE room;
DROP TABLE bed_and_breakfast;
DROP SEQUENCE booking_id;
DROP SEQUENCE room_charge_id;
DROP SEQUENCE guest_id; 
DROP SEQUENCE payment_id;
DROP DOMAIN room_type;
DROP DOMAIN room_view;
DROP DOMAIN room_floor;
DROP DOMAIN booking_type;
DROP DOMAIN booking_status;
DROP DOMAIN room_ensuite_type;
DROP DOMAIN payment_method;
DROP DOMAIN guest_title;
DROP DOMAIN guests;

/* ------------------------------------------------------ */
/* Domain: room_type                                      */
/* Purpose: Room type domain (constraint C25)             */
/* ------------------------------------------------------ */
CREATE DOMAIN room_type CHARACTER VARYING(40) NOT NULL
	CONSTRAINT room_type_value CHECK (VALUE = 'Standard Single' 
		OR VALUE = 'Standard Double' 
		OR VALUE = 'Standard Twin' 
		OR VALUE = 'Standard Family (Double+Single)' 
		OR VALUE = 'Standard Family (Double+Bunks)' 
		OR VALUE = 'Deluxe Single' 
		OR VALUE = 'Deluxe Double' 
		OR VALUE = 'Deluxe Twin' 
		OR VALUE = 'Deluxe Family (Double+Single)' 
		OR VALUE = 'Deluxe Family (Double+Bunks)');

/* ------------------------------------------------------ */
/* Domain: guest_title                                    */
/* Purpose: Guest title domain (constraint C20)           */
/* ------------------------------------------------------ */
CREATE DOMAIN guest_title CHARACTER VARYING(10)
	CONSTRAINT guest_title_value CHECK (VALUE = 'Mr.' 
		OR VALUE = 'Mrs.' 
		OR VALUE = 'Miss' 
		OR VALUE = 'Ms.' 
		OR VALUE = 'Mr. & Mrs.' 
		OR VALUE = 'Lady' 
		OR VALUE = 'Dr.' 
		OR VALUE = 'Prof.' 
		OR VALUE = 'Rev.' 
		OR VALUE IS NULL);

/* ------------------------------------------------------ */
/* Domain: room_view                                      */
/* Purpose: Room view domain (constraint C26)             */
/* ------------------------------------------------------ */
CREATE DOMAIN room_view CHARACTER VARYING(20) NOT NULL
	CONSTRAINT room_view_value CHECK (VALUE = 'Sea View' 
		OR VALUE = 'Town View');

/* ------------------------------------------------------ */
/* Domain: guests                                         */
/* Purpose: Guests domain (constraint C3)                 */
/* ------------------------------------------------------ */
CREATE DOMAIN guests INTEGER NOT NULL
	CONSTRAINT guests_value CHECK (VALUE >= 0);

/* ------------------------------------------------------ */
/* Domain: booking_type                                   */
/* Purpose: Booking type domain (constraint C17)          */
/* ------------------------------------------------------ */
CREATE DOMAIN booking_type CHARACTER VARYING(30) NOT NULL
	CONSTRAINT booking_type_value CHECK (VALUE = 'Bed Only' 
		OR VALUE = 'Bed and Breakfast' 
		OR VALUE = 'Dinner, Bed and Breakfast');

/* ------------------------------------------------------ */
/* Domain: room_ensuite_type                              */
/* Purpose: Room ensuite type domain (constraint C23)     */
/* ------------------------------------------------------ */
CREATE DOMAIN room_ensuite_type CHARACTER VARYING(30) NOT NULL
	CONSTRAINT room_ensuite_type_value CHECK (VALUE = 'Shared Facilities' 
		OR VALUE = 'Private Facilities' 
		OR VALUE = 'En-suite (with Shower)'  
		OR VALUE = 'En-suite (with Bath)');

/* ------------------------------------------------------ */
/* Domain: room_floor                                     */
/* Purpose: Room floor domain (constraint C24)            */
/* ------------------------------------------------------ */
CREATE DOMAIN room_floor CHARACTER VARYING(20) NOT NULL
	CONSTRAINT room_floor_value CHECK (VALUE = 'Ground Floor' 
		OR VALUE = 'First Floor' 
		OR VALUE = 'Second Floor');

/* ------------------------------------------------------ */
/* Domain: payment_method                                 */
/* Purpose: Payment method domain (constraint C22)        */
/* ------------------------------------------------------ */
CREATE DOMAIN payment_method CHARACTER VARYING(20) NOT NULL
	CONSTRAINT payment_method_value CHECK (VALUE = 'Cash' 
		OR VALUE = 'Cheque' 
		OR VALUE = 'Credit Card' 
		OR VALUE = 'Debit Card' 
		OR VALUE = 'Paypal' 
		OR VALUE = 'Bank Transfer');

/* ------------------------------------------------------ */
/* Domain: booking_status                                 */
/* Purpose: Allowable booking states (constraint C16)     */
/* ------------------------------------------------------ */
CREATE DOMAIN booking_status CHARACTER VARYING(20) NOT NULL
	CONSTRAINT booking_status_value CHECK (VALUE = 'Provisional' 
		OR VALUE = 'Confirmed' 
		OR VALUE = 'Cancelled');

/* ------------------------------------------------------ */
/* Sequence: booking_id                                   */
/* Purpose: Postgresql generated booking id               */
/* ------------------------------------------------------ */
CREATE SEQUENCE booking_id
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;

/* ------------------------------------------------------ */
/* Sequence: room_charge_id                               */
/* Purpose: Postgresql generated room_charge_id           */
/* ------------------------------------------------------ */
CREATE SEQUENCE room_charge_id
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;

/* ------------------------------------------------------ */
/* Sequence: guest_id                                     */
/* Purpose: Postgresql generated guest id                 */
/* ------------------------------------------------------ */
CREATE SEQUENCE guest_id
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;

/* ------------------------------------------------------ */
/* Sequence: payment_id                                   */
/* Purpose: Postgresql generated payment id               */
/* ------------------------------------------------------ */
CREATE SEQUENCE payment_id
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;

/* ------------------------------------------------------ */
/* Table: bed_and_breakfast                               */
/* Purpose: Bed and Breakfasts                            */
/* ------------------------------------------------------ */
CREATE TABLE bed_and_breakfast (
  ref CHARACTER VARYING(20) PRIMARY KEY,
  name CHARACTER VARYING(50) NOT NULL,
  premise CHARACTER VARYING(50),
  thoroughfare CHARACTER VARYING(50),
  locality_name CHARACTER VARYING(50),
  administrative_area CHARACTER VARYING(50),
  postal_code CHARACTER VARYING(50),
  country CHARACTER VARYING(50),
  phone1 CHARACTER VARYING(20),
  phone2 CHARACTER VARYING(20),
  email CHARACTER VARYING(50),
  website CHARACTER VARYING(50),
  vat_number CHARACTER VARYING(30));

/* ------------------------------------------------------ */
/* Table: staff                                           */
/* Purpose: Staff accounts                                 */
/* ------------------------------------------------------ */
CREATE TABLE staff (
  username CHARACTER VARYING(20) PRIMARY KEY,
  fullname CHARACTER VARYING(40) NOT NULL,
  bb_ref CHARACTER VARYING(20),
  password text,
  login_allowed CHARACTER(1) DEFAULT 'N'::bpchar,
  password_expiry date NOT NULL, 
  CONSTRAINT employs FOREIGN KEY (bb_ref) 
    REFERENCES bed_and_breakfast(ref) ON DELETE RESTRICT,
  CONSTRAINT c21_login CHECK (login_allowed IN ('Y', 'N')),
  CONSTRAINT c8_password CHECK(char_length(password) > 7));

/* ------------------------------------------------------ */
/* Table: referrer                                        */
/* Purpose: Sources of guest bookings                     */
/* ------------------------------------------------------ */
CREATE TABLE referrer (
  name CHARACTER VARYING(50) PRIMARY KEY);

/* ------------------------------------------------------ */
/* Table: guest                                           */
/* Purpose: Guests                                        */
/* ------------------------------------------------------ */
CREATE TABLE guest (
  id integer DEFAULT nextval(('guest_id'::text)::regclass) PRIMARY KEY,
  title GUEST_TITLE,
  first_name CHARACTER VARYING(50),
  last_name CHARACTER VARYING(50),
  premise CHARACTER VARYING(50),
  company CHARACTER VARYING(50),
  thoroughfare CHARACTER VARYING(50),
  locality_name CHARACTER VARYING(50),
  administrative_area CHARACTER VARYING(50),
  postal_code CHARACTER VARYING(50),
  country CHARACTER VARYING(50),
  phone1 CHARACTER VARYING(20),
  phone2 CHARACTER VARYING(20),
  email CHARACTER VARYING(50),
  notes TEXT);

/* ------------------------------------------------------ */
/* Table: room                                            */
/* Purpose: B&B rooms                                     */
/* ------------------------------------------------------ */
CREATE TABLE room (
  bb_ref CHARACTER VARYING(20),
  name CHARACTER VARYING(50),
  room_type ROOM_TYPE,
  floor ROOM_FLOOR,
  room_view ROOM_VIEW,
  ensuite ROOM_ENSUITE_TYPE,
  disabled CHARACTER(1) DEFAULT 'N'::bpchar,
  bed_spaces INTEGER,
  max_cots INTEGER,
  PRIMARY KEY(bb_ref, name),
  CONSTRAINT contains FOREIGN KEY (bb_ref) 
    REFERENCES bed_and_breakfast(ref) ON DELETE RESTRICT,
  CONSTRAINT c19_disabled CHECK (disabled IN ('Y', 'N')),
  CONSTRAINT c15_bed_spaces CHECK (bed_spaces > 0 AND bed_spaces < 6),
  CONSTRAINT c18_max_cots CHECK (max_cots >= 0 AND max_cots < 4));

/* ------------------------------------------------------ */
/* Table: booking                                         */
/* Purpose: Guest bookings/reservations                   */
/* ------------------------------------------------------ */
CREATE TABLE booking (
  id integer DEFAULT nextval(('booking_id'::text)::regclass) PRIMARY KEY,
  guest INTEGER,
  status BOOKING_STATUS,
  booking_type BOOKING_TYPE,
  referrer CHARACTER VARYING(50),
  booking_date DATE NOT NULL,
  arrival_date DATE NOT NULL,
  departure_date DATE NOT NULL,
  notes TEXT,
  CONSTRAINT makes FOREIGN KEY (guest) 
    REFERENCES guest(id) ON DELETE RESTRICT,
  CONSTRAINT refers FOREIGN KEY (referrer) 
    REFERENCES referrer(name) ON DELETE RESTRICT,
  CONSTRAINT c4_departure CHECK (departure_date > arrival_date),
  CONSTRAINT c5_booking CHECK (arrival_date >= booking_date));

/* ------------------------------------------------------ */
/* Table: booked_room                                     */
/* Purpose: Booked rooms                                  */
/* ------------------------------------------------------ */
CREATE TABLE booked_room (
  booking_id INTEGER,
  bb_ref CHARACTER VARYING(20),
  room CHARACTER VARYING(50),
  adults GUESTS,
  children GUESTS,
  babies GUESTS,
  cots_reqd INTEGER NOT NULL,
  cost DOUBLE PRECISION NOT NULL,
  notes TEXT,
  PRIMARY KEY (booking_id, bb_ref, room),
  CONSTRAINT let_as FOREIGN KEY (bb_ref, room) 
    REFERENCES room(bb_ref, name) ON DELETE RESTRICT,
  CONSTRAINT reserves FOREIGN KEY (booking_id) 
    REFERENCES booking(id) ON DELETE RESTRICT,
  CONSTRAINT c1_cost CHECK (cost > 0.00));

/* ------------------------------------------------------ */
/* Table: payment                                         */
/* Purpose: Record guest payments                         */
/* ------------------------------------------------------ */
CREATE TABLE payment (
  id integer DEFAULT nextval(('payment_id'::text)::regclass) PRIMARY KEY,
  booking_id INTEGER,
  payment_date DATE NOT NULL,
  amount DOUBLE PRECISION NOT NULL,
  method PAYMENT_METHOD,
  CONSTRAINT settles FOREIGN KEY (booking_id) 
    REFERENCES booking(id) ON DELETE RESTRICT);

/* ------------------------------------------------------ */
/* Table: room_charge                                     */
/* Purpose: Record guest room charges                     */
/* ------------------------------------------------------ */
CREATE TABLE room_charge (
  id INTEGER DEFAULT nextval(('room_charge_id'::text)::regclass) PRIMARY KEY,
  booking_id INTEGER,
  bb_ref CHARACTER VARYING(20),
  room CHARACTER VARYING(50), 
  date_incurred DATE NOT NULL,
  description CHARACTER VARYING(50), 
  amount DOUBLE PRECISION NOT NULL,
  CONSTRAINT incurs FOREIGN KEY (booking_id, bb_ref, room) 
    REFERENCES booked_room(booking_id, bb_ref, room) ON DELETE RESTRICT);

/* ------------------------------------------------------ */
/* Table: tariff                                          */
/* Purpose: Room tariff                                   */
/* ------------------------------------------------------ */
CREATE TABLE tariff (
  bb_ref CHARACTER VARYING(20),
  room_type ROOM_TYPE,
  booking_type BOOKING_TYPE,
  stay_date DATE,
  adult_rate DOUBLE PRECISION NOT NULL,
  child_rate DOUBLE PRECISION NOT NULL,
  baby_rate DOUBLE PRECISION NOT NULL,
  single_surcharge DOUBLE PRECISION NOT NULL,
  PRIMARY KEY (bb_ref, room_type, booking_type, stay_date),
  CONSTRAINT charges_at FOREIGN KEY (bb_ref) 
    REFERENCES bed_and_breakfast(ref) ON DELETE RESTRICT);

/* ------------------------------------------------------ */
/* Table: long_stay_discount                              */
/* Purpose: Details of discounts for longer stays         */
/* ------------------------------------------------------ */
CREATE TABLE long_stay_discount (
  bb_ref CHARACTER VARYING(20),
  stay_nights INTEGER,
  discount DOUBLE PRECISION NOT NULL,
  PRIMARY KEY (bb_ref, stay_nights),
  CONSTRAINT offers FOREIGN KEY (bb_ref) 
    REFERENCES bed_and_breakfast(ref) ON DELETE RESTRICT);

