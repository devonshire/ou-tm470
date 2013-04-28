/* -------------------------------------------------------------- */
/* TM470:  Valid Booked Room                                      */
/* Author: Kevin Peat                                             */
/* Date:   05-May-2012                                            */
/* -------------------------------------------------------------- */

/* -------------------------------------------------------------- */
/* Function: valid_booked_room()                                  */
/* Purpose:  Validate booked_room inserts/updates vs. constraints */
/* -------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION valid_booked_room() RETURNS trigger AS $$

	DECLARE
		v_arrive DATE;
		v_depart DATE;
		v_adults GUESTS := 0;

	BEGIN

		/* Constraint C2 */
		/* A booking must include one or more adults */
		v_adults = NEW.adults + COALESCE((SELECT sum(br.adults) 
			FROM booked_room br 
			WHERE br.booking_id = NEW.booking_id), 0);

		IF (v_adults = 0) THEN
			RAISE EXCEPTION 'A booking must include at least one adult';
		END IF;

		/* Constraint C10 */
		/* Room cannot accommodate more people than available bed spaces */
		IF EXISTS(SELECT	r.name
					 FROM		room r
					 WHERE	r.bb_ref = NEW.bb_ref
					 AND		r.name = NEW.room
					 AND		r.bed_spaces < NEW.adults + NEW.children) THEN

			RAISE EXCEPTION 'Room cannot accommodate more guests than available bed spaces';
		END IF;

		/* Constraint C11 */
		/* Room cannot accommodate more cots than available space allows */
		IF EXISTS(SELECT	r.name
					 FROM		room r
					 WHERE	r.bb_ref = NEW.bb_ref
					 AND		r.name = NEW.room
					 AND		r.max_cots < NEW.cots_reqd) THEN

			RAISE EXCEPTION 'Room cannot accommodate more cots than available spaces';
		END IF;

		/* Constraint C12 */
		/* All rooms linked to a single booking must be at the same B&B */
		IF EXISTS(SELECT	br.booking_id
					 FROM		booked_room br
					 WHERE	br.booking_id = NEW.booking_id
					 AND		br.bb_ref <> NEW.bb_ref) THEN

			RAISE EXCEPTION 'All rooms linked to a single booking must be at the same B&B';
		END IF;

		/* Constraint C6 (see also trigger on booking table) */
		/* A room can only be let once for a particular date  */

		/* Get arrival and departure date for this booking */
		v_arrive = (SELECT arrival_date FROM booking WHERE id = NEW.booking_id);
		v_depart = (SELECT departure_date FROM booking WHERE id = NEW.booking_id);

		/* Look for double bookings */
		IF EXISTS(SELECT	b.id
					 FROM		booked_room br,
								booking b
					 WHERE	b.id = br.booking_id
					 AND		b.id <> NEW.booking_id
					 AND		b.status <> 'Cancelled'
					 AND		br.room = NEW.room
					 AND		br.bb_ref = NEW.bb_ref
					 AND		((b.arrival_date >= v_arrive AND b.arrival_date < v_depart)
					 OR		(b.departure_date > v_arrive AND b.departure_date <= v_depart)
					 OR		(b.arrival_date < v_arrive AND b.departure_date > v_depart))) THEN

			RAISE EXCEPTION 'Double booking of rooms is not allowed';
		END IF;

		RETURN NEW;
	END;

$$ LANGUAGE plpgsql;

DROP TRIGGER valid_booked_room ON booked_room;
CREATE TRIGGER valid_booked_room BEFORE INSERT OR UPDATE ON booked_room
	FOR EACH ROW EXECUTE PROCEDURE valid_booked_room();
