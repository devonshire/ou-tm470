/* -------------------------------------------------------------- */
/* TM470:  Cancel Guest Booking                                   */
/* Author: Kevin Peat                                             */
/* Date:   27-Apr-2012                                            */
/* -------------------------------------------------------------- */

/* -------------------------------------------------------------- */
/* Function: cancel_guest_booking()                               */
/* Purpose:  Cancels a guest booking                              */
/* -------------------------------------------------------------- */
/* Arguments:                                                     */
/*    v_booking_id = Booking Id                                   */
/* Example usage:                                                 */
/*    SELECT cancel_guest_booking(1234);                          */
/* -------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION cancel_guest_booking(v_booking_id integer) 
	RETURNS void AS $$

	BEGIN

		/* Check if booking exists */
		IF NOT EXISTS(SELECT id FROM booking WHERE id = v_booking_id) THEN
			RAISE EXCEPTION 'Invalid booking reference';
		END IF;

		/* Remove any room charges */
		DELETE
		FROM		room_charge
		WHERE		booking_id = v_booking_id;

		/* Remove any payments */
		DELETE
		FROM		payment
		WHERE		booking_id = v_booking_id;

		/* Remove booked rooms */
		DELETE
		FROM		booked_room
		WHERE		booking_id = v_booking_id;

		/* Mark booking as cancelled */
		UPDATE	booking
		SET		status = 'Cancelled'
		WHERE 	id = v_booking_id;

	END;

$$ LANGUAGE plpgsql;
