-- ===================================================================
-- TM470 Application Test Script
-- Author: Kevin Peat
-- Developed: 01-May-2012
-- Uses the pgTap unit testing framework (http://pgtap.org)
-- ===================================================================

-- Turn off echo to keep things quiet
\set ECHO
\set QUIET 1

-- Format the output
\pset format unaligned
\pset tuples_only true
\pset pager

-- Revert all changes on failure
\set ON_ERROR_ROLLBACK 1
\set ON_ERROR_STOP true
\set QUIET 1

-- Tests start
SELECT '=============================================================';
SELECT ' Unit Testing          : Kevin Peat TM470 Project';
SELECT ' Run Time              : ' || now();
SELECT ' Operating System      : ' || os_name();
SELECT ' Postgresql version    : ' || pg_version_num();
SELECT ' pgTap version         : ' || pgtap_version();
SELECT '-------------------------------------------------------------';

SELECT 'TRUNCATE ALL TABLES...';
DELETE FROM payment;
DELETE FROM room_charge;
DELETE FROM booked_room;
DELETE FROM booking;
DELETE FROM staff;
DELETE FROM referrer;
DELETE FROM guest;
DELETE FROM long_stay_discount;
DELETE FROM tariff;
DELETE FROM room;
DELETE FROM bed_and_breakfast;

SELECT 'RESET ALL SEQUENCES TO 1...';
ALTER SEQUENCE booking_id RESTART WITH 1;
ALTER SEQUENCE guest_id RESTART WITH 1;
ALTER SEQUENCE payment_id RESTART WITH 1;
ALTER SEQUENCE room_charge_id RESTART WITH 1;

SELECT '-------------------------------------------------------------';
SELECT 'STARTING TESTS...';

-- Number of tests planned
SELECT plan(117);

SELECT '-------------------------------------------------------------';
SELECT 'TEST SCHEMA CORRECT...';
SELECT tables_are('public', ARRAY[ 'bed_and_breakfast', 'booked_room', 'booking', 'guest', 'long_stay_discount', 'payment', 'referrer', 'room', 'room_charge', 'staff', 'tariff' ]);
SELECT views_are('public', ARRAY[ 'bandb_income', 'debtors', 'guest_bill_bandb', 'guest_bill_booking', 'guest_bill_charges', 'guest_bill_payments', 'guest_bill_rooms', 'guest_income', 'referrer_income', 'unconfirmed_bookings' ]);
SELECT sequences_are('public', ARRAY[ 'booking_id', 'guest_id', 'payment_id', 'room_charge_id' ]);
SELECT domains_are('public', ARRAY[ 'booking_status', 'booking_type', 'guest_title', 'guests', 'payment_method', 'room_ensuite_type', 'room_floor', 'room_type', 'room_view' ]);
SELECT has_trigger('public', 'booked_room', 'valid_booked_room', 'Trigger valid_booked_room exists on table booked_room');
SELECT has_trigger('public', 'booking', 'valid_booking', 'Trigger valid_booking exists on table booking');
SELECT has_trigger('public', 'room_charge', 'valid_room_charge', 'Trigger valid_room_charge exists on table room_charge');
SELECT has_function('cancel_guest_booking', ARRAY[ 'integer' ], 'Function cancel_guest_booking exists');
SELECT has_function('check_room_availability', ARRAY[ 'text', 'text', 'date', 'date', 'numeric', 'numeric', 'numeric' ], 'Function check_room_availability exists');
SELECT has_function('get_room_cost', ARRAY[ 'text', 'text', 'text', 'date', 'date', 'numeric', 'numeric', 'numeric' ], 'Function get_room_cost exists');
SELECT has_function('housekeeping_report', ARRAY[ 'text', 'date' ], 'Function housekeeping_report exists');
SELECT has_function('run_make_guest_booking', 'Function run_make_guest_booking exists');
SELECT has_function('make_guest_booking', ARRAY[ 'text', 'text', 'date', 'date', 'date', 'text', 'text', 'text', 'text', 'text', 'text', 'text', 'text', 'text', 'text', 'text', 'text', 'text' ], 'Function make_guest_booking exists');
SELECT has_function('get_guest_id', ARRAY[ 'text', 'text', 'text', 'text', 'text', 'text', 'text', 'text', 'text', 'text', 'text', 'text' ], 'Function get_guest_id exists');
SELECT has_function('populate_tariff', ARRAY[ 'text', 'date', 'date', 'numeric', 'numeric', 'numeric', 'numeric', 'numeric', 'numeric', 'numeric', 'numeric', 'numeric', 'numeric', 'numeric', 'numeric', 'numeric' ], 'Function populate_tariff exists');
SELECT has_function('populate_tariff_rows', ARRAY[ 'text', 'text', 'text', 'date', 'numeric', 'numeric', 'numeric', 'numeric' ], 'Function populate_tariff_rows exists');
SELECT has_function('move_booked_room', ARRAY[ 'text', 'integer', 'date', 'date', 'text', 'text' ], 'Function move_booked_room exists');
SELECT has_function('check_room_available', ARRAY[ 'text', 'text', 'date', 'date' ], 'Function check_room_available exists');

SELECT '-------------------------------------------------------------';
SELECT 'TEST bed_and_breakfast TABLE (test valid inserts)...';
PREPARE populate_bandb AS INSERT INTO bed_and_breakfast (ref, name, premise, thoroughfare, locality_name, administrative_area, postal_code, country, phone1, email, website, vat_number)
	VALUES	('BB1', 'My First B&B', '123', 'Any Street', 'Any Town', 'Any County', 'XX11 1XX', 'Any Country', '+44 (0)111 1111', 'myemail@zzz.com', 'www.website1.co.uk', '111-111111'), 
				('BB2', 'My Second B&B', '987', 'Some Street', 'Some Town', 'Some County', 'AA11 1AA', 'Some Country', '+44 (0)999 9999', 'myemail@aaa.com', 'www.website2.co.uk', '999-999999');
SELECT lives_ok('populate_bandb', 'Valid inserts to bed_and_breakfast table');
SELECT '';
SELECT 'TEST bed_and_breakfast TABLE (test invalid inserts)...';
PREPARE throw_pkey_bandb AS INSERT INTO bed_and_breakfast (ref, name, premise, thoroughfare, locality_name, administrative_area, postal_code, country, phone1, email, website, vat_number)
	VALUES	('BB1', 'My First B&B', '123', 'Any Street', 'Any Town', 'Any County', 'XX11 1XX', 'Any Country', '+44 (0)111 1111', 'myemail@zzz.com', 'www.website1.co.uk', '111-111111');
SELECT throws_ok('throw_pkey_bandb', '23505', 'duplicate key value violates unique constraint "bed_and_breakfast_pkey"', 'Test violation of primary key for bed_and_breakfast table');

SELECT '-------------------------------------------------------------';
SELECT 'TEST room TABLE (test valid inserts)...';
PREPARE populate_room AS INSERT INTO room (bb_ref, name, room_type, floor, room_view, ensuite, disabled, bed_spaces, max_cots) 
	VALUES	('BB1', 'Room 1', 'Standard Twin', 'Ground Floor', 'Sea View', 'En-suite (with Shower)', 'Y', 2, 0), 
				('BB1', 'Room 2', 'Standard Double', 'Ground Floor', 'Town View', 'En-suite (with Shower)', 'Y', 2, 1), 
				('BB1', 'Room 3', 'Deluxe Double', 'Ground Floor', 'Town View', 'En-suite (with Shower)', 'N', 2, 2), 
				('BB1', 'Room 4', 'Deluxe Double', 'First Floor', 'Town View', 'En-suite (with Bath)', 'N', 2, 0), 
				('BB1', 'Room 5', 'Standard Family (Double+Single)', 'First Floor', 'Town View', 'En-suite (with Shower)', 'N', 3, 1), 
				('BB1', 'Room 6', 'Standard Family (Double+Bunks)', 'Second Floor', 'Sea View', 'En-suite (with Bath)', 'N', 4, 1), 
				('BB2', 'Rose Room', 'Standard Twin', 'Ground Floor', 'Town View', 'En-suite (with Shower)', 'N', 2, 0), 
				('BB2', 'Blue Room', 'Standard Double', 'Ground Floor', 'Sea View', 'En-suite (with Shower)', 'Y', 2, 0), 
				('BB2', 'Pink Room', 'Standard Double', 'First Floor', 'Sea View', 'En-suite (with Bath)', 'N', 2, 1), 
				('BB2', 'Yellow Room', 'Standard Double', 'First Floor', 'Town View', 'En-suite (with Bath)', 'N', 2, 1), 
				('BB2', 'White Room', 'Deluxe Single', 'First Floor', 'Town View', 'En-suite (with Shower)', 'N', 1, 1);
SELECT lives_ok('populate_room', 'Valid inserts to room table');
SELECT '';
SELECT 'TEST room TABLE (test invalid inserts)...';
PREPARE throw_pkey_room AS INSERT INTO room (bb_ref, name, room_type, floor, room_view, ensuite, disabled, bed_spaces, max_cots) 
VALUES ('BB1', 'Room 1', 'Standard Twin', 'Ground Floor', 'Sea View', 'En-suite (with Shower)', 'Y', 2, 0);
SELECT throws_ok('throw_pkey_room', '23505', 'duplicate key value violates unique constraint "room_pkey"', 'Test violation of primary key for room table');
PREPARE throw_constraint_contains AS INSERT INTO room (bb_ref, name, room_type, floor, room_view, ensuite, disabled, bed_spaces, max_cots) VALUES ('BB3', 'Room 1', 'Standard Twin', 'Ground Floor', 'Sea View', 'En-suite (with Shower)', 'Y', 2, 0);
SELECT throws_ok('throw_constraint_contains', '23503', 'insert or update on table "room" violates foreign key constraint "contains"', 'Test violation of "Contains" relationship');
PREPARE throw_constraint_c15 AS INSERT INTO room (bb_ref, name, room_type, floor, room_view, ensuite, disabled, bed_spaces, max_cots) VALUES ('BB1', 'Room 104', 'Standard Twin', 'Ground Floor', 'Sea View', 'En-suite (with Shower)', 'Y', 6, 0);
SELECT throws_ok('throw_constraint_c15', '23514', 'new row for relation "room" violates check constraint "c15_bed_spaces"', 'Test violation of constraint C15');
PREPARE throw_constraint_c18 AS INSERT INTO room (bb_ref, name, room_type, floor, room_view, ensuite, disabled, bed_spaces, max_cots) VALUES ('BB1', 'Room 105', 'Standard Twin', 'Ground Floor', 'Sea View', 'En-suite (with Shower)', 'Y', 2, 4);
SELECT throws_ok('throw_constraint_c18', '23514', 'new row for relation "room" violates check constraint "c18_max_cots"', 'Test violation of constraint C18');
PREPARE throw_constraint_c19 AS INSERT INTO room (bb_ref, name, room_type, floor, room_view, ensuite, disabled, bed_spaces, max_cots) VALUES ('BB1', 'Room 106', 'Standard Twin', 'Ground Floor', 'Sea View', 'En-suite (with Shower)', 'X', 2, 0);
SELECT throws_ok('throw_constraint_c19', '23514', 'new row for relation "room" violates check constraint "c19_disabled"', 'Test violation of constraint C19');
PREPARE throw_constraint_c23 AS INSERT INTO room (bb_ref, name, room_type, floor, room_view, ensuite, disabled, bed_spaces, max_cots) VALUES ('BB1', 'Room 100', 'Standard Twin', 'Ground Floor', 'Sea View', 'Invalid Data', 'Y', 2, 0);
SELECT throws_ok('throw_constraint_c23', '23514', 'value for domain room_ensuite_type violates check constraint "room_ensuite_type_value"', 'Test violation of constraint C23');
PREPARE throw_constraint_c24 AS INSERT INTO room (bb_ref, name, room_type, floor, room_view, ensuite, disabled, bed_spaces, max_cots) VALUES ('BB1', 'Room 101', 'Standard Twin', 'Invalid Data', 'Sea View', 'En-suite (with Shower)', 'Y', 2, 0);
SELECT throws_ok('throw_constraint_c24', '23514', 'value for domain room_floor violates check constraint "room_floor_value"', 'Test violation of constraint C24');
PREPARE throw_constraint_c25 AS INSERT INTO room (bb_ref, name, room_type, floor, room_view, ensuite, disabled, bed_spaces, max_cots) VALUES ('BB1', 'Room 102', 'Invalid Data', 'Ground Floor', 'Sea View', 'En-suite (with Shower)', 'Y', 2, 0);
SELECT throws_ok('throw_constraint_c25', '23514', 'value for domain room_type violates check constraint "room_type_value"', 'Test violation of constraint C25');
PREPARE throw_constraint_c26 AS INSERT INTO room (bb_ref, name, room_type, floor, room_view, ensuite, disabled, bed_spaces, max_cots) VALUES ('BB1', 'Room 103', 'Standard Twin', 'Ground Floor', 'Invalid Data', 'En-suite (with Shower)', 'Y', 2, 0);
SELECT throws_ok('throw_constraint_c26', '23514', 'value for domain room_view violates check constraint "room_view_value"', 'Test violation of constraint C26');

SELECT '-------------------------------------------------------------';
SELECT 'TEST tariff TABLE (test valid inserts)...';
PREPARE populate_tariff1 AS SELECT populate_tariff('BB1', '2012-07-01', '2012-07-31', 25, 10, 0, 5, 5, 0, 10, 6, 0, 5, 2, 0, 15);
SELECT lives_ok('populate_tariff1', 'Valid inserts to tariff table');
PREPARE populate_tariff2 AS SELECT populate_tariff('BB1', '2012-08-01', '2012-08-31', 30, 12, 0, 5, 5, 0, 10, 6, 0, 5, 2, 0, 20);
SELECT lives_ok('populate_tariff2', 'Valid inserts to tariff table');
PREPARE populate_tariff3 AS SELECT populate_tariff('BB2', '2012-07-01', '2012-07-31', 27, 12, 0, 5, 5, 0, 10, 6, 0, 5, 2, 0, 17);
SELECT lives_ok('populate_tariff3', 'Valid inserts to tariff table');
PREPARE populate_tariff4 AS SELECT populate_tariff('BB2', '2012-08-01', '2012-08-31', 32, 14, 0, 5, 5, 0, 10, 6, 0, 5, 2, 0, 22);
SELECT lives_ok('populate_tariff4', 'Valid inserts to tariff table');
SELECT '';
SELECT 'TEST tariff TABLE (test invalid inserts)...';
PREPARE throw_pkey_tariff AS INSERT INTO tariff (bb_ref, room_type, booking_type, stay_date, adult_rate, child_rate, baby_rate, single_surcharge) 
VALUES ('BB1', 'Standard Double', 'Bed and Breakfast', '2012-07-01', 30, 20, 0, 20);
SELECT throws_ok('throw_pkey_tariff', '23505', 'duplicate key value violates unique constraint "tariff_pkey"', 'Test violation of primary key for tariff table');
PREPARE throw_constraint_chargedat AS SELECT populate_tariff('BB3', '2012-08-01', '2012-08-31', 32, 14, 0, 5, 5, 0, 10, 6, 0, 5, 2, 0, 22);
SELECT throws_ok('throw_constraint_chargedat', 'P0001', 'Insert failed, check for key violation', 'Test violation of "ChargedAt" relationship');

SELECT '-------------------------------------------------------------';
SELECT 'TEST long_stay_discount TABLE (test valid inserts)...';
PREPARE populate_lsd AS INSERT INTO long_stay_discount(bb_ref, stay_nights, discount) VALUES('BB1', 3, -6), ('BB1', 4, -8), ('BB1', 5, -10), ('BB1', 6, -14), ('BB1', 7, -18);
SELECT lives_ok('populate_lsd', 'Valid inserts to long_stay_discount table');
SELECT '';
SELECT 'TEST long_stay_discount TABLE (test invalid inserts)...';
PREPARE throw_pkey_long_stay AS INSERT INTO long_stay_discount(bb_ref, stay_nights, discount) VALUES('BB1', 3, -6);
SELECT throws_ok('throw_pkey_long_stay', '23505', 'duplicate key value violates unique constraint "long_stay_discount_pkey"', 'Test violation of primary key for long_stay_discount table');
PREPARE throw_constraint_offers AS INSERT INTO long_stay_discount(bb_ref, stay_nights, discount) VALUES('BB3', 3, -6);
SELECT throws_ok('throw_constraint_offers', '23503', 'insert or update on table "long_stay_discount" violates foreign key constraint "offers"', 'Test violation of "Offers" relationship');

SELECT '-------------------------------------------------------------';
SELECT 'TEST guest TABLE (test valid inserts)...';
PREPARE populate_guest AS INSERT INTO guest (title, first_name, last_name, company, premise, thoroughfare, locality_name, administrative_area, postal_code, country, phone1, phone2, email)
VALUES	('Mr. & Mrs.', 'John', 'Adams', Null, '32A', 'A Street', 'A Town', 'A City', 'AA11 1BB', Null, '01234 567890', Null, 'john@adams.abc'), 
			('Mr.', 'Fred', 'Blogs', Null, '14', 'Main Street', 'My Town', 'My State', '90210', 'USA', '415 555 5555', Null, 'fred@blogs.cba'), 
			('Mrs.', 'Jenna', 'Jones', Null, '44', 'Long Street', 'Big Town', 'Big County', 'FF55 5TT', Null, '09999 999999', Null, 'jenna@jones.gbg'), 
			('Miss', 'Jane', 'Smith', 'A Big Client Ltd.', 'Unit 1', 'Industrial Park', 'A Town', 'A City', 'GG66 9TT', Null, '03434 993499', Null, 'jane@abc.sds'), 
			('Mr.', 'Kevin', 'Davis', 'A Small Client Ltd.', '8', 'New Estate', 'My Town', 'My County', 'FF43 9TT', Null, '04343 993499', Null, 'mike@asc.waw'); 
SELECT lives_ok('populate_guest', 'Valid inserts to guest table');
SELECT '';
SELECT 'TEST guest TABLE (test invalid inserts)...';
PREPARE throw_pkey_guest AS INSERT INTO guest (id, title, first_name, last_name, company, premise, thoroughfare, locality_name, administrative_area, postal_code, country, phone1, phone2, email) 
VALUES (1, 'Mr. & Mrs.', 'John', 'Adams', Null, '32A', 'A Street', 'A Town', 'A City', 'AA11 1BB', Null, '01234 567890', Null, 'john@adams.abc');
SELECT throws_ok('throw_pkey_guest', '23505', 'duplicate key value violates unique constraint "guest_pkey"', 'Test violation of primary key for guest table');
PREPARE throw_constraint_c20 AS INSERT INTO guest (title, first_name, last_name, company, premise, thoroughfare, locality_name, administrative_area, postal_code, country, phone1, phone2, email) 
VALUES	('Invalid', 'David', 'Smith', Null, '32A', 'A Street', 'A Town', 'A City', 'AA11 1BB', Null, '01234 567890', Null, 'john@adams.abc');
SELECT throws_ok('throw_constraint_c20', '23514', 'value for domain guest_title violates check constraint "guest_title_value"', 'Test violation of constraint C20');

SELECT '-------------------------------------------------------------';
SELECT 'TEST staff TABLE (test valid inserts)...';
PREPARE populate_staff AS INSERT INTO staff (username, fullname, bb_ref, password, login_allowed, password_expiry) 
VALUES ('john', 'John Smith', 'BB1', 'XXXXXXXXXX', 'Y', '2012-12-31'), ('bob', 'Bob Martin', 'BB2', 'XXXXXXXXXX', 'Y', '2012-12-31');
SELECT lives_ok('populate_staff', 'Valid inserts to staff table');
SELECT '';
SELECT 'TEST staff TABLE (test invalid inserts)...';
PREPARE throw_pkey_staff AS INSERT INTO staff (username, fullname, bb_ref, password, login_allowed, password_expiry) 
VALUES ('john', 'John Smith', 'BB1', 'XXXXXXXXXX', 'Y', '2012-12-31'), ('bob', 'Bob Martin', 'BB2', 'XXXXXXXXXX', 'Y', '2012-12-31');
SELECT throws_ok('throw_pkey_staff', '23505', 'duplicate key value violates unique constraint "staff_pkey"', 'Test violation of primary key for staff table');
PREPARE throw_constraint_employs AS INSERT INTO staff (username, fullname, bb_ref, password, login_allowed, password_expiry) VALUES ('somebody', 'somebody', 'BB3', 'XXXXXXXXXX', 'Y', '2012-12-31');
SELECT throws_ok('throw_constraint_employs', '23503', 'insert or update on table "staff" violates foreign key constraint "employs"', 'Test violation of "Employs" relationship');
PREPARE throw_constraint_c8 AS INSERT INTO staff (username, fullname, bb_ref, password, login_allowed, password_expiry) VALUES ('josie', 'Josie Fox', 'BB1', 'INVALID', 'Y', '2012-12-31');
SELECT throws_ok('throw_constraint_c8', '23514', 'new row for relation "staff" violates check constraint "c8_password"', 'Test violation of constraint C8');
PREPARE throw_constraint_c21 AS INSERT INTO staff (username, fullname, bb_ref, password, login_allowed, password_expiry) VALUES ('diana', 'Diane Day', 'BB1', 'XXXXXXXXXX', 'X', '2012-12-31');
SELECT throws_ok('throw_constraint_c21', '23514', 'new row for relation "staff" violates check constraint "c21_login"', 'Test violation of constraint C21');

SELECT '-------------------------------------------------------------';
SELECT 'TEST referrer TABLE (test valid inserts)...';
PREPARE populate_referrer AS INSERT INTO referrer (name) VALUES('Passing Trade'), ('Personal Recommendation'), ('Our Website'), ('Unknown'), ('Returning Guest'), ('Tourist Information Centres');
SELECT lives_ok('populate_referrer', 'Valid inserts to referrer table');
SELECT '';
SELECT 'TEST referrer TABLE (test invalid inserts)...';
PREPARE throw_pkey_referrer AS INSERT INTO referrer (name) VALUES('Passing Trade');
SELECT throws_ok('throw_pkey_referrer', '23505', 'duplicate key value violates unique constraint "referrer_pkey"', 'Test violation of primary key for referrer table');

SELECT '-------------------------------------------------------------';
SELECT 'TEST booking TABLE (test valid inserts)...';
PREPARE populate_booking AS INSERT INTO booking (guest, status, booking_type, referrer, booking_date, arrival_date, departure_date, notes) 
VALUES	(1, 'Confirmed', 'Bed and Breakfast', 'Unknown', '2012-01-01', '2012-07-05', '2012-07-10', Null), 
			(2, 'Confirmed', 'Bed Only', 'Our Website', '2012-04-06', '2012-07-08', '2012-07-15', Null), 
			(3, 'Provisional', 'Bed Only', 'Unknown', '2012-02-08', '2012-08-05', '2012-08-15', 'A Note'), 
			(4, 'Confirmed', 'Bed and Breakfast', 'Unknown', '2012-02-08', '2012-08-07', '2012-08-13', 'A Note'),
			(5, 'Confirmed', 'Bed and Breakfast', 'Unknown', '2012-02-08', '2012-08-20', '2012-08-22', Null),
			(4, 'Confirmed', 'Bed and Breakfast', 'Unknown', '2012-02-08', '2012-08-20', '2012-08-22', Null),
			(1, 'Confirmed', 'Bed and Breakfast', 'Returning Guest', '2012-04-01', '2012-08-05', '2012-08-10', Null), 
			(2, 'Confirmed', 'Bed and Breakfast', 'Returning Guest', '2012-04-26', '2012-08-10', '2012-08-15', Null);
SELECT lives_ok('populate_booking', 'Valid inserts to booking table');
SELECT '';
SELECT 'TEST booking TABLE (test invalid inserts)...';
PREPARE throw_pkey_booking AS INSERT INTO booking (id, guest, status, booking_type, referrer, booking_date, arrival_date, departure_date, notes) 
VALUES	(1, 1, 'Confirmed', 'Bed and Breakfast', 'Unknown', '2012-01-01', '2016-07-05', '2016-07-10', Null);
SELECT throws_ok('throw_pkey_booking', '23505', 'duplicate key value violates unique constraint "booking_pkey"', 'Test violation of primary key for booking table');
PREPARE throw_constraint_makes AS INSERT INTO booking (guest, status, booking_type, referrer, booking_date, arrival_date, departure_date, notes) VALUES (999, 'Provisional', 'Bed and Breakfast', 'Unknown', '2012-01-01', '2012-07-05', '2012-07-10', Null);
SELECT throws_ok('throw_constraint_makes', '23503', 'insert or update on table "booking" violates foreign key constraint "makes"', 'Test violation of "Makes" relationship');
PREPARE throw_constraint_refers AS INSERT INTO booking (guest, status, booking_type, referrer, booking_date, arrival_date, departure_date, notes) VALUES (1, 'Provisional', 'Bed and Breakfast', 'INVALID', '2012-01-01', '2012-07-05', '2012-07-10', Null);
SELECT throws_ok('throw_constraint_refers', '23503', 'insert or update on table "booking" violates foreign key constraint "refers"', 'Test violation of "Refers" relationship');
PREPARE throw_constraint_c4 AS INSERT INTO booking (guest, status, booking_type, referrer, booking_date, arrival_date, departure_date, notes) VALUES (1, 'Provisional', 'Bed and Breakfast', 'Unknown', '2012-01-01', '2012-07-05', '2012-07-01', Null);
SELECT throws_ok('throw_constraint_c4', '23514', 'new row for relation "booking" violates check constraint "c4_departure"', 'Test violation of constraint C4');
PREPARE throw_constraint_c5 AS INSERT INTO booking (guest, status, booking_type, referrer, booking_date, arrival_date, departure_date, notes) VALUES (1, 'Provisional', 'Bed and Breakfast', 'Unknown', '2013-01-01', '2012-07-05', '2012-07-10', Null);
SELECT throws_ok('throw_constraint_c5', '23514', 'new row for relation "booking" violates check constraint "c5_booking"', 'Test violation of constraint C5');
PREPARE throw_constraint_c16 AS INSERT INTO booking (guest, status, booking_type, referrer, booking_date, arrival_date, departure_date, notes) VALUES (1, 'INVALID', 'Bed and Breakfast', 'Unknown', '2012-01-01', '2012-07-05', '2012-07-10', Null);
SELECT throws_ok('throw_constraint_c16', '23514', 'value for domain booking_status violates check constraint "booking_status_value"', 'Test violation of constraint C16');
PREPARE throw_constraint_c17 AS INSERT INTO booking (guest, status, booking_type, referrer, booking_date, arrival_date, departure_date, notes) VALUES (1, 'Provisional', 'INVALID', 'Unknown', '2012-01-01', '2012-07-05', '2012-07-10', Null);
SELECT throws_ok('throw_constraint_c17', '23514', 'value for domain booking_type violates check constraint "booking_type_value"', 'Test violation of constraint C17');

SELECT '-------------------------------------------------------------';
SELECT 'TEST booked_room TABLE (test valid inserts)...';
PREPARE populate_booked_room AS INSERT INTO booked_room (booking_id, bb_ref, room, adults, children, babies, cots_reqd, cost, notes) 
VALUES	(1, 'BB1', 'Room 1', 2, 0, 0, 0, 250, Null), 
			(1, 'BB1', 'Room 2', 2, 0, 0, 0, 300, 'A Note'), 
			(2, 'BB2', 'Rose Room', 1, 1, 0, 0, 200, Null),
			(3, 'BB1', 'Room 2', 1, 1, 0, 0, 200, Null), 
			(3, 'BB1', 'Room 3', 2, 0, 0, 0, 300, Null),
			(7, 'BB1', 'Room 1', 2, 0, 0, 0, 275, Null), 
			(7, 'BB1', 'Room 4', 2, 0, 0, 0, 330, '2 x vegetarians'), 
			(7, 'BB1', 'Room 5', 1, 0, 0, 0, 140, Null), 
			(8, 'BB1', 'Room 5', 2, 0, 0, 0, 300, 'Nut allergy');
SELECT lives_ok('populate_booked_room', 'Valid inserts to booked_room table');
SELECT '';
SELECT 'TEST booked_room TABLE (test invalid inserts)...';
PREPARE throw_pkey_booked_room AS INSERT INTO booked_room (booking_id, bb_ref, room, adults, children, babies, cots_reqd, cost, notes) VALUES (1, 'BB1', 'Room 1', 2, 0, 0, 0, 250, Null);
SELECT throws_ok('throw_pkey_booked_room', '23505', 'duplicate key value violates unique constraint "booked_room_pkey"', 'Test violation of primary key for booked_room table');
PREPARE throw_constraint_letas AS INSERT INTO booked_room (booking_id, bb_ref, room, adults, children, babies, cots_reqd, cost, notes) VALUES (4, 'BB4', 'Room 3', 2, 0, 0, 0, 200, Null);
SELECT throws_ok('throw_constraint_letas', '23503', 'insert or update on table "booked_room" violates foreign key constraint "let_as"', 'Test violation of "LetAs" relationship');
PREPARE throw_constraint_reserves AS INSERT INTO booked_room (booking_id, bb_ref, room, adults, children, babies, cots_reqd, cost, notes) VALUES (9999, 'BB1', 'Room 3', 2, 0, 0, 0, 200, Null);
SELECT throws_ok('throw_constraint_reserves', '23503', 'insert or update on table "booked_room" violates foreign key constraint "reserves"', 'Test violation of "Reserves" relationship');
PREPARE throw_constraint_c1 AS INSERT INTO booked_room (booking_id, bb_ref, room, adults, children, babies, cots_reqd, cost, notes) VALUES (1, 'BB1', 'Room 3', 2, 0, 0, 0, 0, Null);
SELECT throws_ok('throw_constraint_c1', '23514', 'new row for relation "booked_room" violates check constraint "c1_cost"', 'Test violation of constraint C1');
PREPARE throw_constraint_c2 AS INSERT INTO booked_room (booking_id, bb_ref, room, adults, children, babies, cots_reqd, cost, notes) VALUES (4, 'BB1', 'Room 3', 0, 0, 0, 0, 0, Null);
SELECT throws_ok('throw_constraint_c2', 'P0001', 'A booking must include at least one adult', 'Test violation of constraint C2');
PREPARE throw_constraint_c3 AS INSERT INTO booked_room (booking_id, bb_ref, room, adults, children, babies, cots_reqd, cost, notes) VALUES (1, 'BB1', 'Room 4', 2, -1, 0, 0, 250, Null);
SELECT throws_ok('throw_constraint_c3', '23514', 'value for domain guests violates check constraint "guests_value"', 'Test violation of constraint C3');
PREPARE throw_constraint_c6 AS INSERT INTO booked_room (booking_id, bb_ref, room, adults, children, babies, cots_reqd, cost, notes) VALUES (4, 'BB1', 'Room 2', 1, 0, 0, 0, 250, Null);
SELECT throws_ok('throw_constraint_c6', 'P0001', 'Double booking of rooms is not allowed', 'Test violation of constraint C6');
PREPARE throw_constraint_c10 AS INSERT INTO booked_room (booking_id, bb_ref, room, adults, children, babies, cots_reqd, cost, notes) VALUES (1, 'BB1', 'Room 6', 99, 0, 0, 0, 250, Null);
SELECT throws_ok('throw_constraint_c10', 'P0001', 'Room cannot accommodate more guests than available bed spaces', 'Test violation of constraint C10');
PREPARE throw_constraint_c11 AS INSERT INTO booked_room (booking_id, bb_ref, room, adults, children, babies, cots_reqd, cost, notes) VALUES (1, 'BB1', 'Room 6', 1, 0, 1, 99, 250, Null);
SELECT throws_ok('throw_constraint_c11', 'P0001', 'Room cannot accommodate more cots than available spaces', 'Test violation of constraint C11');
PREPARE throw_constraint_c12 AS INSERT INTO booked_room (booking_id, bb_ref, room, adults, children, babies, cots_reqd, cost, notes) VALUES (1, 'BB2', 'Rose Room', 1, 0, 0, 0, 250, Null);
SELECT throws_ok('throw_constraint_c12', 'P0001', 'All rooms linked to a single booking must be at the same B&B', 'Test violation of constraint C12');

SELECT '-------------------------------------------------------------';
SELECT 'TEST payment TABLE (test valid inserts)...';
PREPARE populate_payment AS INSERT INTO payment (booking_id, payment_date, amount, method) 
VALUES	(1, '2012-01-05', 100, 'Credit Card'), 
			(1, '2012-02-01', 200, 'Debit Card'), 
			(2, '2012-04-06', 150, 'Paypal');
SELECT lives_ok('populate_payment', 'Valid inserts to payment table');
SELECT '';
SELECT 'TEST payment TABLE (test invalid inserts)...';
PREPARE throw_pkey_payment AS INSERT INTO payment (id, booking_id, payment_date, amount, method) VALUES (1, 1, '2012-01-05', 100, 'Credit Card');
SELECT throws_ok('throw_pkey_payment', '23505', 'duplicate key value violates unique constraint "payment_pkey"', 'Test violation of primary key for payment table');
PREPARE throw_constraint_settles AS INSERT INTO payment (booking_id, payment_date, amount, method) VALUES (9999, '2012-01-05', 100, 'Credit Card');
SELECT throws_ok('throw_constraint_settles', '23503', 'insert or update on table "payment" violates foreign key constraint "settles"', 'Test violation of "Settles" relationship');
PREPARE throw_constraint_c22 AS INSERT INTO payment (booking_id, payment_date, amount, method) VALUES (1, '2012-01-05', 100, 'INVALID');
SELECT throws_ok('throw_constraint_c22', '23514', 'value for domain payment_method violates check constraint "payment_method_value"', 'Test violation of constraint C22');

SELECT '-------------------------------------------------------------';
SELECT 'TEST room_charge TABLE (test valid inserts)...';
PREPARE populate_room_charge AS INSERT INTO room_charge (booking_id, bb_ref, room, date_incurred, description, amount) 
VALUES	(1, 'BB1', 'Room 1', '2012-07-08', 'Flowers in Room', 10), 
			(2, 'BB2', 'Rose Room', '2012-07-10', 'Guest Laundry', 20), 
			(2, 'BB2', 'Rose Room', '2012-07-11', 'Champagne', 30);
SELECT lives_ok('populate_room_charge', 'Valid inserts to room_charge table');
SELECT '';
SELECT 'TEST room_charge TABLE (test invalid inserts)...';
PREPARE throw_pkey_room_charge AS INSERT INTO room_charge (id, booking_id, bb_ref, room, date_incurred, description, amount) VALUES (1, 1, 'BB1', 'Room 1', '2012-07-08', 'Flowers in Room', 10);
SELECT throws_ok('throw_pkey_room_charge', '23505', 'duplicate key value violates unique constraint "room_charge_pkey"', 'Test violation of primary key for room_charge table');
PREPARE throw_constraint_incurs AS INSERT INTO room_charge (booking_id, bb_ref, room, date_incurred, description, amount) VALUES (1, 'BB4', 'Room 1', '2012-07-08', 'Flowers in Room', 10);
SELECT throws_ok('throw_constraint_incurs', '23503', 'insert or update on table "room_charge" violates foreign key constraint "incurs"', 'Test violation of "Incurs" relationship');
PREPARE throw_constraint_c7 AS INSERT INTO room_charge (booking_id, bb_ref, room, date_incurred, description, amount) VALUES (1, 'BB1', 'Room 1', '2014-07-08', 'Flowers in Room', 10);
SELECT throws_ok('throw_constraint_c7', 'P0001', 'Room charge date must be during guest stay', 'Test violation of constraint C7');

-- Additional DB tests
SELECT '-------------------------------------------------------------';
SELECT 'ADDITIONAL DB TESTS...';

-- Constraint C6 also needs testing via updating the booking table
PREPARE throw_constraint_c6b AS UPDATE booking SET departure_date = '2012-08-10' WHERE id = 1;
SELECT throws_ok('throw_constraint_c6b', 'P0001', 'Double booking of rooms is not allowed', 'Test violation of constraint C6 (via booking table)');

-- An exception should be thrown if room rates are requested and no tariff exists
PREPARE throw_no_tariff AS SELECT get_room_cost('BB1', 'Deluxe Double', 'Bed Only', '2015-01-01', '2015-01-05', 2, 0, 0);
SELECT throws_ok('throw_no_tariff', 'P0001', 'No tariff found for these dates', 'Throw an exception if room rates are requested for dates where no tariff exists');

-- Test reports
SELECT '-------------------------------------------------------------';
SELECT 'TEST REPORTS...';
PREPARE test_referrer_income_sql1 AS SELECT referrer::text, SUM(cost)::text as income FROM referrer_income WHERE booking_date >= '2012-03-01' AND booking_date <= '2012-06-30' GROUP BY referrer ORDER BY income desc;
PREPARE test_referrer_income_rst1 AS VALUES ('Our Website', '200'), ('Returning Guest', '1045');
SELECT results_eq('test_referrer_income_sql1', 'test_referrer_income_rst1', 'Test Referrer Income Report returns expected results (with date range)');
PREPARE test_referrer_income_sql2 AS SELECT referrer::text, SUM(cost)::text as income FROM referrer_income GROUP BY referrer ORDER BY income desc;
PREPARE test_referrer_income_rst2 AS VALUES ('Our Website', '200'), ('Unknown', '1050'), ('Returning Guest', '1045');
SELECT results_eq('test_referrer_income_sql2', 'test_referrer_income_rst2', 'Test Referrer Income Report returns expected results (all dates)');
PREPARE test_referrer_income_sql3 AS SELECT referrer::text, SUM(cost)::text as income FROM referrer_income WHERE booking_date >= '2022-03-01' AND booking_date <= '2022-06-30' GROUP BY referrer ORDER BY income desc;
SELECT is_empty('test_referrer_income_sql3', 'Test Referrer Income Report returns expected results (empty resultset)');
PREPARE test_unconfirmed_bookings_report_sql AS SELECT bandb_name::text, booking_id::text, guest_name::text, arrival_date::text FROM unconfirmed_bookings;
PREPARE test_unconfirmed_bookings_report_rst AS VALUES ('My First B&B','3','Mrs. Jenna Jones','2012-08-05');
SELECT results_eq('test_unconfirmed_bookings_report_sql', 'test_unconfirmed_bookings_report_rst', 'Test Unconfirmed Bookings Report returns expected results');
PREPARE test_bandb_income_report_sql1 AS SELECT name::text, sum(cost)::text as income FROM bandb_income WHERE booking_date >= '2012-04-01' AND booking_date <= '2012-06-30' GROUP BY name ORDER BY income desc;
PREPARE test_bandb_income_report_rst1 AS VALUES ('My Second B&B', '200'), ('My First B&B', '1045');
SELECT results_eq('test_bandb_income_report_sql1', 'test_bandb_income_report_rst1', 'Test B&B Income Report returns expected results (with date range)');
PREPARE test_bandb_income_report_sql2 AS SELECT name::text, sum(cost)::text as income FROM bandb_income GROUP BY name ORDER BY income desc;
PREPARE test_bandb_income_report_rst2 AS VALUES ('My First B&B', '2095'), ('My Second B&B', '200');
SELECT results_eq('test_bandb_income_report_sql2', 'test_bandb_income_report_rst2', 'Test B&B Income Report returns expected results (all dates)');
PREPARE test_bandb_income_report_sql3 AS SELECT name::text, sum(cost)::text as income FROM bandb_income WHERE booking_date >= '2022-04-01' AND booking_date <= '2022-06-30' GROUP BY name ORDER BY income desc;
SELECT is_empty('test_bandb_income_report_sql3', 'Test B&B Income Report returns expected results (empty resultset)');
PREPARE test_debtors_report_sql1 AS SELECT bandb_name::text, booking_ref::text, guest_name::text, arrival_date::text, departure_date::text, booking_cost::text, room_charges::text, payment_recd::text, booking_cost::text, room_charges::text, payment_recd::text FROM debtors WHERE (booking_cost + room_charges - payment_recd) <> 0;
PREPARE test_debtors_report_rst1 AS VALUES ('My First B&B','1','Mr. & Mrs. John Adams','2012-07-05','2012-07-10','550','10','300','550','10','300'),
                                           ('My Second B&B','2','Mr. Fred Blogs','2012-07-08','2012-07-15','200','50','150','200','50','150'),
                                           ('My First B&B','3','Mrs. Jenna Jones','2012-08-05','2012-08-15','500','0','0','500','0','0'),
                                           ('My First B&B','7','Mr. & Mrs. John Adams','2012-08-05','2012-08-10','745','0','0','745','0','0'),
                                           ('My First B&B','8','Mr. Fred Blogs','2012-08-10','2012-08-15','300','0','0','300','0','0');
SELECT results_eq('test_debtors_report_sql1', 'test_debtors_report_rst1', 'Test Debtors Report returns expected results');
PREPARE test_housekeeping_report_sql1 AS SELECT activity::text, guest_name::text, room::text, adults::text, children::text, babies::text, cots_reqd::text FROM housekeeping_report('BB1',  '2012-08-10');
PREPARE test_housekeeping_report_rst1 AS VALUES ('1. CHECKING OUT', 'Mr. & Mrs. John Adams', 'Room 1', '2', '0', '0', '0'),
                                                ('1. CHECKING OUT', 'Mr. & Mrs. John Adams', 'Room 4', '2', '0', '0', '0'),
                                                ('1. CHECKING OUT', 'Mr. & Mrs. John Adams', 'Room 5', '1', '0', '0', '0'),
                                                ('2. STAYING', 'Mrs. Jenna Jones', 'Room 2', '1', '1', '0', '0'),
                                                ('2. STAYING', 'Mrs. Jenna Jones', 'Room 3', '2', '0', '0', '0'),
                                                ('3. CHECKING IN', 'Mr. Fred Blogs', 'Room 5', '2', '0', '0', '0');
SELECT results_eq('test_housekeeping_report_sql1', 'test_housekeeping_report_rst1', 'Test Housekeeping Report returns expected results');
PREPARE test_housekeeping_report_sql2 AS SELECT activity::text, guest_name::text, room::text, adults::text, children::text, babies::text, cots_reqd::text FROM housekeeping_report('BB1',  '2012-07-11');
SELECT is_empty('test_housekeeping_report_sql2', 'Test Housekeeping Report returns expected results (empty resultset)');
PREPARE test_guest_income_report_sql1 AS SELECT guest_name::text, SUM(cost)::text as income FROM guest_income WHERE booking_date >= '2012-04-01' AND booking_date <= '2012-06-30' GROUP BY guest_name, company ORDER BY income desc;
PREPARE test_guest_income_report_rst1 AS VALUES ('Mr. & Mrs. John Adams','745'), ('Mr. Fred Blogs','500');
SELECT results_eq('test_guest_income_report_sql1', 'test_guest_income_report_rst1', 'Test Guest Income Report returns expected results (with date range)');
PREPARE test_guest_income_report_sql2 AS SELECT guest_name::text, SUM(cost)::text as income FROM guest_income GROUP BY guest_name, company ORDER BY guest_name;
PREPARE test_guest_income_report_rst2 AS VALUES ('Mr. Fred Blogs','500'), ('Mr. & Mrs. John Adams','1295'), ('Mrs. Jenna Jones','500');
SELECT results_eq('test_guest_income_report_sql2', 'test_guest_income_report_rst2', 'Test Guest Income Report returns expected results (all dates)');
PREPARE test_guest_bill_sql1 AS SELECT booking_ref::text, name::text, premise::text, thoroughfare::text, phone1::text, email::text FROM guest_bill_bandb WHERE booking_ref = 1;
PREPARE test_guest_bill_sql2 AS SELECT booking_ref::text, booking_type::text, arrival_date::text, departure_date::text, guest_name::text FROM guest_bill_booking WHERE booking_ref = 1;
PREPARE test_guest_bill_sql3 AS SELECT booking_ref::text, room::text, cost::text FROM guest_bill_rooms WHERE booking_ref = 1;
PREPARE test_guest_bill_sql4 AS SELECT booking_ref::text, room::text, date_incurred::text, description::text, amount::text FROM guest_bill_charges WHERE booking_ref = 1;
PREPARE test_guest_bill_sql5 AS SELECT booking_ref::text, payment_date::text, amount::text, method::text FROM guest_bill_payments WHERE booking_ref = 1;
PREPARE test_guest_bill_rst1 AS VALUES ('1','My First B&B','123','Any Street','+44 (0)111 1111','myemail@zzz.com');
PREPARE test_guest_bill_rst2 AS VALUES ('1','Bed and Breakfast','2012-07-05','2012-07-10','Mr. & Mrs. John Adams');
PREPARE test_guest_bill_rst3 AS VALUES ('1','Room 1','250'), ('1','Room 2','300');
PREPARE test_guest_bill_rst4 AS VALUES ('1','Room 1','2012-07-08','Flowers in Room','10');
PREPARE test_guest_bill_rst5 AS VALUES ('1','2012-01-05','100','Credit Card'), ('1','2012-02-01','200','Debit Card');
SELECT results_eq('test_guest_bill_sql1', 'test_guest_bill_rst1', 'Test Guest Bill Report returns expected results (B&B)');
SELECT results_eq('test_guest_bill_sql2', 'test_guest_bill_rst2', 'Test Guest Bill Report returns expected results (Booking)');
SELECT results_eq('test_guest_bill_sql3', 'test_guest_bill_rst3', 'Test Guest Bill Report returns expected results (Rooms)');
SELECT results_eq('test_guest_bill_sql4', 'test_guest_bill_rst4', 'Test Guest Bill Report returns expected results (Charges)');
SELECT results_eq('test_guest_bill_sql5', 'test_guest_bill_rst5', 'Test Guest Bill Report returns expected results (Payments)');

-- Additional DB tests
SELECT '-------------------------------------------------------------';
SELECT 'ADDITIONAL TRANSACTION TESTS...';
PREPARE test_check_room_availability_sql1 AS SELECT bb_ref::text, name::text, room_type::text, floor::text, room_view::text, cost::text FROM check_room_availability('BB1', 'Bed and Breakfast', '2012-08-05', '2012-08-10', 2, 1, 0);
PREPARE test_check_room_availability_rst1 AS VALUES ('BB1','Room 6','Standard Family (Double+Bunks)','Second Floor','Sea View','415');
SELECT results_eq('test_check_room_availability_sql1', 'test_check_room_availability_rst1', 'Test Check Room Availability returns expected results');
PREPARE test_check_room_availability_sql2 AS SELECT bb_ref::text, name::text, room_type::text, floor::text, room_view::text, cost::text FROM check_room_availability('BB1', 'Bed and Breakfast', '2012-08-05', '2012-08-10', 1, 0, 0);
PREPARE test_check_room_availability_rst2 AS VALUES ('BB1','Room 6','Standard Family (Double+Bunks)','Second Floor','Sea View','265');
SELECT results_eq('test_check_room_availability_sql2', 'test_check_room_availability_rst2', 'Test Check Room Availability returns expected results');
PREPARE test_check_room_availability_sql3 AS SELECT bb_ref::text, name::text, room_type::text, floor::text, room_view::text, cost::text FROM check_room_availability('BB1', 'Bed and Breakfast', '2012-07-08', '2012-07-10', 2, 1, 0);
PREPARE test_check_room_availability_rst3 AS VALUES ('BB1','Room 5','Standard Family (Double+Single)','First Floor','Town View','150'),
                                                    ('BB1','Room 6','Standard Family (Double+Bunks)','Second Floor','Sea View','150');
SELECT results_eq('test_check_room_availability_sql3', 'test_check_room_availability_rst3', 'Test Check Room Availability returns expected results');
PREPARE test_check_room_availability_sql4 AS SELECT bb_ref::text, name::text, room_type::text, floor::text, room_view::text, cost::text FROM check_room_availability('BB1', 'Bed and Breakfast', '2012-07-08', '2012-07-10', 1, 0, 0);
PREPARE test_check_room_availability_rst4 AS VALUES ('BB1','Room 3','Deluxe Double','Ground Floor','Town View','100'),
                                                    ('BB1','Room 4','Deluxe Double','First Floor','Town View','100'), 
                                                    ('BB1','Room 5','Standard Family (Double+Single)','First Floor','Town View','60'), 
                                                    ('BB1','Room 6','Standard Family (Double+Bunks)','Second Floor','Sea View','90');
SELECT results_eq('test_check_room_availability_sql4', 'test_check_room_availability_rst4', 'Test Check Room Availability returns expected results');
PREPARE test_check_room_availability_sql5 AS SELECT bb_ref::text, name::text, room_type::text, floor::text, room_view::text, cost::text FROM check_room_availability('BB1', 'Bed and Breakfast', '2012-07-08', '2012-07-10', 2, 0, 0);
PREPARE test_check_room_availability_rst5 AS VALUES ('BB1','Room 3','Deluxe Double','Ground Floor','Town View','140'),
                                                    ('BB1','Room 4','Deluxe Double','First Floor','Town View','140'), 
                                                    ('BB1','Room 5','Standard Family (Double+Single)','First Floor','Town View','120'), 
                                                    ('BB1','Room 6','Standard Family (Double+Bunks)','Second Floor','Sea View','120');
SELECT results_eq('test_check_room_availability_sql5', 'test_check_room_availability_rst5', 'Test Check Room Availability returns expected results');
PREPARE test_make_guest_booking_sql1 AS SELECT * from run_make_guest_booking();
PREPARE test_make_guest_booking_sql2 AS SELECT * from run_make_guest_booking2();
PREPARE test_make_guest_booking_rst1 AS VALUES (15);
PREPARE test_make_guest_booking_rst2 AS VALUES (16);
SELECT results_eq('test_make_guest_booking_sql1', 'test_make_guest_booking_rst1', 'Test Make Guest Booking function returns expected results');
SELECT results_eq('test_make_guest_booking_sql2', 'test_make_guest_booking_rst2', 'Test Make Guest Booking function returns expected results');
PREPARE test_guest_bill_sql6 AS SELECT booking_ref::text, name::text, premise::text, thoroughfare::text, phone1::text, email::text FROM guest_bill_bandb WHERE booking_ref = 15;
PREPARE test_guest_bill_sql7 AS SELECT booking_ref::text, booking_type::text, arrival_date::text, departure_date::text, guest_name::text FROM guest_bill_booking WHERE booking_ref = 15;
PREPARE test_guest_bill_sql8 AS SELECT booking_ref::text, room::text, cost::text FROM guest_bill_rooms WHERE booking_ref = 15;
PREPARE test_guest_bill_rst6 AS VALUES ('15','My First B&B','123','Any Street','+44 (0)111 1111','myemail@zzz.com');
PREPARE test_guest_bill_rst7 AS VALUES ('15','Bed and Breakfast','2012-07-20','2012-07-25','Mr. John Smith');
PREPARE test_guest_bill_rst8 AS VALUES ('15','Room 1','330'), ('15','Room 2','280'), ('15','Room 3','150');
SELECT results_eq('test_guest_bill_sql6', 'test_guest_bill_rst6', 'Test that booking 15 was correctly recorded (B&B)');
SELECT results_eq('test_guest_bill_sql7', 'test_guest_bill_rst7', 'Test that booking 15 was correctly recorded (Booking)');
SELECT results_eq('test_guest_bill_sql8', 'test_guest_bill_rst8', 'Test that booking 15 was correctly recorded (Rooms)');
PREPARE test_guest_bill_sql9 AS SELECT booking_ref::text, name::text, premise::text, thoroughfare::text, phone1::text, email::text FROM guest_bill_bandb WHERE booking_ref = 16;
PREPARE test_guest_bill_sql10 AS SELECT booking_ref::text, booking_type::text, arrival_date::text, departure_date::text, guest_name::text FROM guest_bill_booking WHERE booking_ref = 16;
PREPARE test_guest_bill_sql11 AS SELECT booking_ref::text, room::text, cost::text FROM guest_bill_rooms WHERE booking_ref = 16;
PREPARE test_guest_bill_rst9 AS VALUES ('16','My First B&B','123','Any Street','+44 (0)111 1111','myemail@zzz.com');
PREPARE test_guest_bill_rst10 AS VALUES ('16','Bed and Breakfast','2012-07-23','2012-07-27','Mr. David Davis');
PREPARE test_guest_bill_rst11 AS VALUES ('16','Room 4','150'), ('16','Room 5','150');
SELECT results_eq('test_guest_bill_sql9', 'test_guest_bill_rst9', 'Test that booking 16 was correctly recorded (B&B)');
SELECT results_eq('test_guest_bill_sql10', 'test_guest_bill_rst10', 'Test that booking 16 was correctly recorded (Booking)');
SELECT results_eq('test_guest_bill_sql11', 'test_guest_bill_rst11', 'Test that booking 16 was correctly recorded (Rooms)');
PREPARE test_move_booked_room_sql1 AS SELECT move_booked_room('BB1', '15', '2012-07-20','2012-07-25', 'Room 1', 'Room 6');
PREPARE test_move_booked_room_rst1 AS VALUES (true);
SELECT results_eq('test_move_booked_room_sql1', 'test_move_booked_room_rst1', 'Test Move Booked Room returns expected results');
PREPARE test_guest_bill_sql12 AS SELECT booking_ref::text, name::text, premise::text, thoroughfare::text, phone1::text, email::text FROM guest_bill_bandb WHERE booking_ref = 15;
PREPARE test_guest_bill_sql13 AS SELECT booking_ref::text, booking_type::text, arrival_date::text, departure_date::text, guest_name::text FROM guest_bill_booking WHERE booking_ref = 15;
PREPARE test_guest_bill_sql14 AS SELECT booking_ref::text, room::text, cost::text FROM guest_bill_rooms WHERE booking_ref = 15;
PREPARE test_guest_bill_rst12 AS VALUES ('15','My First B&B','123','Any Street','+44 (0)111 1111','myemail@zzz.com');
PREPARE test_guest_bill_rst13 AS VALUES ('15','Bed and Breakfast','2012-07-20','2012-07-25','Mr. John Smith');
PREPARE test_guest_bill_rst14 AS VALUES ('15','Room 2','280'), ('15','Room 3','150'), ('15','Room 6','330');
SELECT results_eq('test_guest_bill_sql12', 'test_guest_bill_rst12', 'Test that booking 15 was correctly amended (B&B)');
SELECT results_eq('test_guest_bill_sql13', 'test_guest_bill_rst13', 'Test that booking 15 was correctly amended (Booking)');
SELECT results_eq('test_guest_bill_sql14', 'test_guest_bill_rst14', 'Test that booking 15 was correctly amended (Rooms)');
PREPARE test_cancel_booking_sql1 AS SELECT * FROM cancel_guest_booking(1);
SELECT lives_ok('test_cancel_booking_sql1', 'Test Cancel Booking returns correct results');
PREPARE test_cancel_booking_sql2 AS SELECT * FROM booked_room WHERE booking_id = 1;
SELECT is_empty('test_cancel_booking_sql2', 'Test that booking 1 was correctly cancelled (Rooms)');
PREPARE test_cancel_booking_sql3 AS SELECT * FROM room_charge WHERE booking_id = 1;
SELECT is_empty('test_cancel_booking_sql3', 'Test that booking 1 was correctly cancelled (Charges)');
PREPARE test_cancel_booking_sql4 AS SELECT * FROM payment WHERE booking_id = 1;
SELECT is_empty('test_cancel_booking_sql4', 'Test that booking 1 was correctly cancelled (Payments)');
PREPARE test_cancel_booking_sql5 AS SELECT status::text FROM booking WHERE id = 1;
PREPARE test_cancel_booking_rst5 AS VALUES ('Cancelled');
SELECT results_eq('test_cancel_booking_sql5', 'test_cancel_booking_rst5', 'Test that booking 1 was correctly cancelled (Booking)');

-- Tests finished
SELECT '';
SELECT '=============================================================';
SELECT 'TESTS COMPLETED';
SELECT '=============================================================';

-- Finish the tests
SELECT * FROM finish();
