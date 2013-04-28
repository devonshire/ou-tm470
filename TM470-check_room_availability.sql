/* -------------------------------------------------------------- */
/* TM470:  Check Room Availability                                */
/* Author: Kevin Peat                                             */
/* Date:   18-Apr-2012                                            */
/* -------------------------------------------------------------- */

/* -------------------------------------------------------------- */
/* Function: get_room_cost()                                      */
/* Purpose:  Retrieve room cost                                   */
/* -------------------------------------------------------------- */
/* Arguments:                                                     */
/*    v_bb_ref = Bed and breakfast reference                      */
/*    v_room_type = Room type                                     */
/*    v_booking_type = Booking type                               */
/*    v_arrive = Arrival date for stay                            */
/*    v_depart = Departure date for stay                          */
/*    v_adults = Number of adults staying in room                 */
/*    v_children = Number of children staying in room             */
/*    v_babies = Number of babies staying in room                 */
/* Example usage:                                                 */
/*    SELECT get_room_cost('BB1', 'Deluxe Double',                */
/*    'Bed and Breakfast', '2012-08-03', '2012-08-08', 2, 0, 0);  */
/* -------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION get_room_cost(v_bb_ref text, 
		v_room_type text, v_booking_type text, 
		v_arrive date, v_depart date, v_adults numeric, 
		v_children numeric, v_babies numeric) RETURNS numeric AS $$

	DECLARE
		v_cost NUMERIC := 0;
		v_cost_row RECORD;
		v_discount_row RECORD;
		v_single_row RECORD;
		v_days INTEGER := v_depart - v_arrive;

	BEGIN
	
		/* Get total cost per person for this stay*/
		FOR v_cost_row IN
			SELECT	SUM(t.adult_rate) as adult_cost, 
						SUM(t.child_rate) as child_cost, 
						SUM(t.baby_rate) as baby_cost
			FROM 		tariff t
			WHERE 	t.bb_ref = v_bb_ref 
			AND		t.room_type = v_room_type 
			AND		t.booking_type = v_booking_type 
			AND		t.stay_date >= v_arrive 
			AND		t.stay_date < v_depart LOOP

			/* Check cost returned and calculate stay costs */
			IF (v_cost_row.adult_cost > 0) THEN
				v_cost := (v_adults * v_cost_row.adult_cost) 
								+ (v_children * v_cost_row.child_cost) 
								+ (v_babies * v_cost_row.baby_cost);
			END IF;

		END LOOP;

		/* If no cost calculated then tariff is missing */
		IF (v_cost = 0) THEN
			RAISE EXCEPTION 'No tariff found for these dates';
		END IF;

		/* Check for long stay discounts */
		FOR v_discount_row IN
			SELECT	*
			FROM 		long_stay_discount d
			WHERE 	d.bb_ref = v_bb_ref 
			AND		d.stay_nights = v_days LOOP

			/* Apply any discount returned */
			IF (v_discount_row.discount != 0) THEN
				v_cost := v_cost + (v_discount_row.discount * v_adults);
			END IF;

		END LOOP;

		/* Apply any single supplement */
		IF (v_adults + v_children + v_babies = 1) THEN

			FOR v_single_row IN
				SELECT	*
				FROM 		tariff t
				WHERE 	t.bb_ref = v_bb_ref 
				AND		t.room_type = v_room_type 
				AND		t.booking_type = v_booking_type 
				AND		t.stay_date = v_arrive 
				AND		t.room_type NOT LIKE '%Single%' LOOP

				/* Check cost returned and calculate stay costs */
				IF (v_single_row.single_surcharge > 0) THEN
					v_cost := v_cost + (v_single_row.single_surcharge * v_days);
				END IF;

			END LOOP;

		END IF;

		RETURN v_cost;
	END;

$$ LANGUAGE plpgsql;

/* -------------------------------------------------------------- */
/* Function: check_room_availability()                            */
/* Purpose:  Retrieve details of available rooms and their costs, */
/*           that is those that are not already booked and could  */
/*           accommodate the guests specified. They are not       */
/*           necessarily the rooms that would be offered to       */
/*           the guests just rooms that could accommodate them.   */
/*           So an enquiry for a single guest would return all    */
/*           available rooms and it would be upto the front-end   */
/*           application to determine which of those rooms are    */
/*           actually offered to the guest to book. For instance, */
/*           at busy times of the year a B&B may not want to      */
/*           accommodate single guests in double rooms but in the */
/*           off-season that may be acceptable if no single       */
/*           rooms are available.                                 */
/* -------------------------------------------------------------- */
/* Arguments:                                                     */
/*    v_bb_ref = Bed and breakfast reference                      */
/*    v_room_type = Room type                                     */
/*    v_booking_type = Booking type                               */
/*    v_arrive = Arrival date for stay                            */
/*    v_depart = Departure date for stay                          */
/*    v_adults = Number of adults staying in room                 */
/*    v_children = Number of children staying in room             */
/*    v_babies = Number of babies staying in room                 */
/* Example usage:                                                 */
/*    SELECT check_room_availability('BB1', 'Bed and Breakfast',  */
/*    '2012-08-03', '2012-08-08', 2, 0, 0);                       */
/* -------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION check_room_availability(v_bb_ref text, 
		v_booking_type text, v_arrive date, v_depart date, v_adults numeric, 
		v_children numeric, v_babies numeric) RETURNS TABLE (
		bb_ref character varying(20), name character varying(20), 
		room_type room_type, floor room_floor, room_view room_view,
		ensuite room_ensuite_type, disabled character(1),
		bed_spaces integer, max_cots integer, cost numeric) AS $$

	BEGIN

		/* Get all rooms at the chosen B&B that could potentially */
		/* accommodate the number of guests specified */
		CREATE TEMP TABLE tmp_rooms ON COMMIT DROP AS
		SELECT	r.bb_ref, 
					r.name, 
					r.room_type, 
					r.floor, 
					r.room_view,
					r.ensuite, 
					r.disabled, 
					r.bed_spaces, 
					r.max_cots,
					0.0 as cost
		FROM		room r
		WHERE		r.bed_spaces >= v_adults + v_children
		AND		r.max_cots >= v_babies
		AND		r.bb_ref = v_bb_ref;

		/* Remove rooms that have a clashing booking */
		DELETE
		FROM		tmp_rooms r
		USING		booked_room br,
					booking b
		WHERE		br.room = r.name
		AND		b.id = br.booking_id
		AND		b.status <> 'Cancelled'
		AND		br.bb_ref = v_bb_ref
		AND		((b.arrival_date >= v_arrive AND b.arrival_date < v_depart)
		OR			(b.departure_date > v_arrive AND b.departure_date <= v_depart)
		OR			(b.arrival_date < v_arrive AND b.departure_date > v_depart));

		/* Add room costs */
		UPDATE 	tmp_rooms
		SET		cost = get_room_cost(v_bb_ref, tmp_rooms.room_type, 
						v_booking_type, v_arrive, v_depart, v_adults, 
						v_children, v_babies);

		/* Return available rooms and their costs */
		RETURN QUERY
			SELECT	r.bb_ref, 
						r.name,
						r.room_type, 
						r.floor, 
						r.room_view,
						r.ensuite, 
						r.disabled, 
						r.bed_spaces, 
						r.max_cots,
						r.cost
			FROM		tmp_rooms r;

	END;

$$ LANGUAGE plpgsql;
