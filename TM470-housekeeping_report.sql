/* -------------------------------------------------------------- */
/* TM470:  Housekeeping Report                                    */
/* Author: Kevin Peat                                             */
/* Date:   27-Apr-2012                                            */
/* -------------------------------------------------------------- */

/* -------------------------------------------------------------- */
/* Function: housekeeping_report()                                */
/* Purpose:  Provides information for the housekeeping department */
/*           at a particular B&B to complete their daily          */
/*           activities, namely details of guests that are        */
/*           checking out, those that are staying and any new     */
/*           arrivals                                             */
/* -------------------------------------------------------------- */
/* Arguments:                                                     */
/*    v_bb_ref = Bed and breakfast reference                      */
/*    v_date = Date to run report for                             */
/* Example usage:                                                 */
/*    SELECT housekeeping_report('BB1', '2012-08-03');            */
/* -------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION housekeeping_report(v_bb_ref text, 
		v_date date) RETURNS TABLE (activity text, 
		guest_name text, room character varying(50), adults guests, 
		children guests, babies guests, cots_reqd integer) AS $$

	BEGIN

		RETURN QUERY

			/* Checking out */
			SELECT		'1. CHECKING OUT' as activity,
							g.title || ' ' || g.first_name || ' ' || g.last_name as guest_name,
							br.room,
							br.adults,
							br.children,
							br.babies,
							br.cots_reqd
			FROM			booking b,
							booked_room br,
							guest g
			WHERE			b.id = br.booking_id
			AND			b.departure_date = v_date
			AND			br.bb_ref = v_bb_ref
			AND			b.guest = g.id
			AND			b.status <> 'Cancelled'

			UNION

			/* Staying */
			SELECT		'2. STAYING' as activity,
							g.title || ' ' || g.first_name || ' ' || g.last_name as guest_name,
							br.room,
							br.adults,
							br.children,
							br.babies,
							br.cots_reqd
			FROM			booking b,
							booked_room br,
							guest g
			WHERE			b.id = br.booking_id
			AND			b.arrival_date < v_date
			AND			b.departure_date > v_date
			AND			br.bb_ref = v_bb_ref
			AND			b.guest = g.id
			AND			b.status <> 'Cancelled'

			UNION

		/* New arrivals */
			SELECT		'3. CHECKING IN' as activity,
							g.title || ' ' || g.first_name || ' ' || g.last_name as guest_name,
							br.room,
							br.adults,
							br.children,
							br.babies,
							br.cots_reqd
			FROM			booking b,
							booked_room br,
							guest g
			WHERE			b.id = br.booking_id
			AND			b.arrival_date = v_date
			AND			br.bb_ref = v_bb_ref
			AND			b.guest = g.id
			AND			b.status <> 'Cancelled'

			ORDER BY		activity,
							room;

	END;

$$ LANGUAGE plpgsql;
