/* -------------------------------------------------------------- */
/* TM470:  Guest Bill                                             */
/* Author: Kevin Peat                                             */
/* Date:   27-Apr-2012                                            */
/* -------------------------------------------------------------- */

/* -------------------------------------------------------------- */
/* B&B Details                                                    */
/* -------------------------------------------------------------- */
/* Example usage:                                                 */
/*    SELECT * FROM guest_bill_bandb WHERE booking_ref = 1        */
/* -------------------------------------------------------------- */
CREATE OR REPLACE VIEW guest_bill_bandb AS

	SELECT DISTINCT	br.booking_id AS booking_ref,
							bb.name,
							bb.premise,
							bb.thoroughfare,
							bb.locality_name,
							bb.administrative_area,
							bb.postal_code,
							bb.country,
							bb.phone1,
							bb.phone2,
							bb.email,
							bb.website,
							bb.vat_number
	FROM					bed_and_breakfast bb,
							booked_room br
	WHERE 				bb.ref = br.bb_ref;

/* -------------------------------------------------------------- */
/* Booking Details                                                */
/* -------------------------------------------------------------- */
/* Example usage:                                                 */
/*    SELECT * FROM guest_bill_booking WHERE booking_ref = 1      */
/* -------------------------------------------------------------- */
CREATE OR REPLACE VIEW guest_bill_booking AS

	SELECT	b.id as booking_ref,
				b.booking_type,
				b.arrival_date,
				b.departure_date,
				g.title || ' ' || g.first_name || ' ' || g.last_name as guest_name,
				g.company,
				g.premise,
				g.thoroughfare,
				g.locality_name,
				g.administrative_area,
				g.postal_code,
				g.country
	FROM		guest g,
				booking b
	WHERE		g.id = b.guest;

/* -------------------------------------------------------------- */
/* Rooms Occupied                                                 */
/* -------------------------------------------------------------- */
/* Example usage:                                                 */
/*    SELECT * FROM guest_bill_rooms WHERE booking_ref = 1        */
/* -------------------------------------------------------------- */
CREATE OR REPLACE VIEW guest_bill_rooms AS

	SELECT	booking_id AS booking_ref,
				room,
				cost
	FROM		booked_room;

/* -------------------------------------------------------------- */
/* Room Charges                                                   */
/* -------------------------------------------------------------- */
/* Example usage:                                                 */
/*    SELECT * FROM guest_bill_charges WHERE booking_ref = 1      */
/* -------------------------------------------------------------- */
CREATE OR REPLACE VIEW guest_bill_charges AS

	SELECT	booking_id AS booking_ref,
				room, 
				date_incurred,
				description, 
				amount
	FROM		room_charge;

/* -------------------------------------------------------------- */
/* Payments Received                                              */
/* -------------------------------------------------------------- */
/* Example usage:                                                 */
/*    SELECT * FROM guest_bill_payments WHERE booking_ref = 1     */
/* -------------------------------------------------------------- */
CREATE OR REPLACE VIEW guest_bill_payments AS

	SELECT	booking_id AS booking_ref,
				payment_date,
				amount,
				method
	FROM		payment;
