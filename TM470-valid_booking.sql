/* -------------------------------------------------------------- */
/* TM470:  Valid Booking                                          */
/* Author: Kevin Peat                                             */
/* Date:   06-May-2012                                            */
/* -------------------------------------------------------------- */

/* -------------------------------------------------------------- */
/* Function: valid_booking()                                      */
/* Purpose:  Validate booking inserts/updates vs. constraints     */
/* -------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION valid_booking() RETURNS trigger AS $$

	DECLARE
		v_room_row RECORD;

	BEGIN

		/* Constraint C6 (see also trigger on booked_room table) */
		/* A room can only be let once for a particular date  */

		/* Not interested in cancelled bookings */
		if (NEW.status <> 'Cancelled') THEN

			/* Need to check each booked room associated with this */
			/* booking for possible double bookings */
			FOR v_room_row IN
				SELECT	*
				FROM		booked_room br
				WHERE		br.booking_id = NEW.id LOOP

				/* Look for double bookings */
				IF EXISTS(SELECT b.id
					FROM	booked_room br,
							booking b
					WHERE	b.id = br.booking_id
					AND	b.id <> NEW.id
					AND	b.status <> 'Cancelled'
					AND	br.room = v_room_row.room 
					AND	br.bb_ref = v_room_row.bb_ref 
					AND	((b.arrival_date >= NEW.arrival_date AND b.arrival_date < NEW.departure_date)
					OR		(b.departure_date > NEW.arrival_date AND b.departure_date <= NEW.departure_date)
					OR		(b.arrival_date < NEW.arrival_date AND b.departure_date > NEW.departure_date))) THEN

					RAISE EXCEPTION 'Double booking of rooms is not allowed';
				END IF;
			END LOOP;
		END IF;

		RETURN NEW;
	END;

$$ LANGUAGE plpgsql;

DROP TRIGGER valid_booking ON booking;
CREATE TRIGGER valid_booking BEFORE INSERT OR UPDATE ON booking
	FOR EACH ROW EXECUTE PROCEDURE valid_booking();
