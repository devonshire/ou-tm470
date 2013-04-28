/* -------------------------------------------------------------- */
/* TM470:  Valid Room Charge (constraint C7)                      */
/* Author: Kevin Peat                                             */
/* Date:   05-May-2012                                            */
/* -------------------------------------------------------------- */

/* -------------------------------------------------------------- */
/* Function: valid_room_charge()                                  */
/* Purpose:  Trigger to check that room charges are only incurred */
/*           during a guest's stay                                */
/* -------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION valid_room_charge() RETURNS trigger AS $$

	BEGIN
		IF NOT EXISTS(SELECT	b.id
						  FROM	booking b
						  WHERE	b.id = NEW.booking_id
						  AND		b.status <> 'Cancelled'
						  AND		b.arrival_date <= NEW.date_incurred
						  AND		b.departure_date >= NEW.date_incurred) THEN

			RAISE EXCEPTION 'Room charge date must be during guest stay';
		END IF;
		
		RETURN NEW;
	END;

$$ LANGUAGE plpgsql;

DROP TRIGGER valid_room_charge ON room_charge;
CREATE TRIGGER valid_room_charge BEFORE INSERT OR UPDATE ON room_charge
	FOR EACH ROW EXECUTE PROCEDURE valid_room_charge();
