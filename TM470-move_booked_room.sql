/* -------------------------------------------------------------- */
/* Function: move_booked_room()                                   */
/* Purpose:  Allows a booked room entity to be allocated to a     */
/*           different room and returns true if successful        */
/*           and false if not                                     */
/* -------------------------------------------------------------- */
/* Arguments:                                                     */
/*    v_bb_ref = B&B reference                                    */
/*    v_booking_id = Booking reference                            */
/*    v_arrive = Arrival date for stay                            */
/*    v_depart = Departure date for stay                          */
/*    v_room_from = Room name to move booking from                */
/*    v_room_to = Room name to move booking to                    */
/* Example usage:                                                 */
/*    SELECT move_booked_room('BB1', 123456, '2012-08-03',        */
/*    '2012-08-08', 'Room 1', 'Room 2');                          */
/* -------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION move_booked_room(v_bb_ref text, 
		v_booking_id integer, v_arrive date, v_depart date, 
		v_room_from text, v_room_to text) RETURNS boolean AS $$

	BEGIN

		/* if new room is free then reallocate booking to new room */
		IF (SELECT check_room_available(v_bb_ref, v_room_to, v_arrive, v_depart)) THEN

			UPDATE booked_room
			SET room = v_room_to
			WHERE booking_id = v_booking_id
			AND room = v_room_from;

			RETURN true;
		
		END IF;

		/* New room wasn't available so reallocation failed */
		RETURN false;

	END;

$$ LANGUAGE plpgsql;

/* -------------------------------------------------------------- */
/* Function: check_room_available()                               */
/* Purpose:  Checks if a specific room at a specific B&B is       */
/*           available for a specific date range and returns      */
/*           true if available and false if not                   */
/* -------------------------------------------------------------- */
/* Arguments:                                                     */
/*    v_bb_ref = Bed and breakfast reference                      */
/*    v_room_name = Room name                                     */
/*    v_arrive = Arrival date for stay                            */
/*    v_depart = Departure date for stay                          */
/* Example usage:                                                 */
/*    SELECT check_room_available('BB1', 'Room 1', '2012-08-03',  */
/*    '2012-08-08');                                              */
/* -------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION check_room_available(v_bb_ref text, 
		v_room_name text, v_arrive date, v_depart date) RETURNS boolean AS $$

	BEGIN

		/* Look for conflicting bookings */
		IF NOT EXISTS(
			SELECT	*
			FROM		booked_room br,
						booking b
			WHERE		b.id = br.booking_id
			AND		b.status <> 'Cancelled'
			AND		br.bb_ref = v_bb_ref
			AND		br.room = v_room_name
			AND		((b.arrival_date >= v_arrive AND b.arrival_date < v_depart)
			OR			(b.departure_date > v_arrive AND b.departure_date <= v_depart)
			OR			(b.arrival_date < v_arrive AND b.departure_date > v_depart))
		) THEN
			RETURN true;
		
		END IF;

		RETURN false;
	END;

$$ LANGUAGE plpgsql;

