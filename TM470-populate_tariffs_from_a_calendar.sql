/* -------------------------------------------------------------- */
/* TM470:  Populate Tariffs From A Calendar                       */
/* Author: Kevin Peat                                             */
/* Date:   16-Apr-2012                                            */
/* -------------------------------------------------------------- */

/* -------------------------------------------------------------- */
/* Function: populate_tariff_rows()                               */
/* Purpose:  Populate main tariff calendar (does actual inserts)  */
/*           Called only from populate_tariff()                   */
/* -------------------------------------------------------------- */
/* Arguments:                                                     */
/*    v_bb_ref = Bed and breakfast reference                      */
/*    v_room_type = Room type, 'Standard%' or 'Deluxe%'           */
/*    v_booking_type = Booking type eg. 'Bed Only'                */
/*    v_stay_date = Date for tariff                               */
/*    v_adult_rate = Adult tariff                                 */
/*    v_child_rate = Child tariff                                 */
/*    v_baby_rate = Baby tariff                                   */
/*    v_single = Single supplement (per night)                    */
/* Example usage:                                                 */
/*    SELECT populate_tariff_rows('BB1', 'Standard%', 'Bed Only', */
/*              '2012-04-01', 25, 10, 0, 15);                     */
/* -------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION populate_tariff_rows(v_bb_ref text, 
		v_room_type text, v_booking_type text, v_stay_date date, 
		v_adult_rate numeric, v_child_rate numeric, 
		v_baby_rate numeric, v_single numeric) RETURNS VOID AS $$

	BEGIN
		/* Insert a tariff record for the specified date for each of */
		/* the specified type of room existing at this B&B */
		INSERT INTO tariff(bb_ref, room_type, booking_type, 
								 stay_date, adult_rate, child_rate, 
								 baby_rate, single_surcharge)
		SELECT DISTINCT 	v_bb_ref, 
								r.room_type,
								v_booking_type,
								v_stay_date,
								v_adult_rate,
								v_child_rate,
								v_baby_rate,
								v_single
		FROM 					room r
		WHERE 				r.bb_ref = v_bb_ref
		AND 					r.room_type LIKE v_room_type;

		/* Rather than an error being raised, data will just not be */
		/* inserted if a primary/foreign key is violated so we should */
		/* let the calling function know */
		IF NOT FOUND THEN
			RAISE EXCEPTION 'Insert failed, check for key violation';      
			RETURN;
		END IF;
	END;

$$ LANGUAGE plpgsql;

/* -------------------------------------------------------------- */
/* Function: populate_tariff()                                    */
/* Purpose:  Populate main tariff calendar                        */
/* -------------------------------------------------------------- */
/* Arguments:                                                     */
/*    v_bb_ref = Bed and breakfast reference                      */
/*    v_stay_from = Starting date for tariff                      */
/*    v_stay_to = Finishing date for tariff (inclusive)           */
/*    v_sr_adult = Cost of staying in a standard room (for adult) */
/*    v_sr_child = Cost of staying in a standard room (for child) */
/*    v_sr_baby = Cost of staying in a standard room (for baby)   */
/*    v_bf_adult = Additional cost of breakfast (for an adult)    */
/*    v_bf_child = Additional cost of breakfast (for an child)    */
/*    v_bf_baby = Additional cost of breakfast (for an baby)      */
/*    v_em_adult = Additional cost of evening meal (for an adult) */
/*    v_em_child = Additional cost of eveniung meal (for an child)*/
/*    v_em_baby = Additional cost of evening meal (for an baby)   */
/*    v_dx_adult = Additional cost of deluxe room (for an adult)  */
/*    v_dx_child = Additional cost of deluxe room (for an child)  */
/*    v_dx_baby = Additional cost of deluxe room (for an baby)    */
/*    v_single = Single supplement (per night)                    */
/* Example usage:                                                 */
/*    SELECT populate_tariff('BB1', '2012-04-01', '2012-06-30',   */
/*              25, 10, 0, 5, 5, 0, 10, 6, 0, 5, 2, 0, 15);       */
/* -------------------------------------------------------------- */
CREATE OR REPLACE FUNCTION populate_tariff(v_bb_ref text, 
		v_stay_from date, v_stay_to date, v_sr_adult numeric, 
		v_sr_child numeric, v_sr_baby numeric, v_bf_adult numeric, 
		v_bf_child numeric, v_bf_baby numeric, v_em_adult numeric, 
		v_em_child numeric, v_em_baby numeric, v_dx_adult numeric, 
		v_dx_child numeric, v_dx_baby numeric, v_single numeric
		) RETURNS VOID AS $$

	DECLARE
		v_date DATE := v_stay_from;
		v_duration INTERVAL := '1 day'::interval;

	BEGIN
		/* Remove any previous tariffs for this B&B and date range */
		DELETE
		FROM		tariff
		WHERE		bb_ref = v_bb_ref
		AND		stay_date >= v_stay_from
		AND		stay_date <= v_stay_to;

		/* Loop through each date that this tariff covers */
		WHILE v_date <= v_stay_to LOOP

			/* Add tariffs for standard rooms */
			PERFORM populate_tariff_rows(v_bb_ref,
								'Standard%',
								'Bed Only',
								v_date,
								v_sr_adult,
								v_sr_child,
								v_sr_baby,
								v_single);

			PERFORM populate_tariff_rows(v_bb_ref,
								'Standard%',
								'Bed and Breakfast',
								v_date,
								v_sr_adult + v_bf_adult,
								v_sr_child + v_bf_child,
								v_sr_baby + v_bf_baby,
								v_single);

			PERFORM populate_tariff_rows(v_bb_ref,
								'Standard%',
								'Dinner, Bed and Breakfast',
								v_date,
								v_sr_adult + v_bf_adult + v_em_adult,
								v_sr_child + v_bf_child + v_em_child,
								v_sr_baby + v_bf_baby + v_em_baby,
								v_single);

			/* Add tariffs for deluxe rooms */
			PERFORM populate_tariff_rows(v_bb_ref,
								'Deluxe%',
								'Bed Only',
								v_date,
								v_sr_adult + v_dx_adult,
								v_sr_child + v_dx_child,
								v_sr_baby + v_dx_baby,
								v_single);

			PERFORM populate_tariff_rows(v_bb_ref,
								'Deluxe%',
								'Bed and Breakfast',
								v_date,
								v_sr_adult + v_bf_adult + v_dx_adult,
								v_sr_child + v_bf_child + v_dx_child,
								v_sr_baby + v_bf_baby + v_dx_baby,
								v_single);

			PERFORM populate_tariff_rows(v_bb_ref,
								'Deluxe%',
								'Dinner, Bed and Breakfast',
								v_date,
								v_sr_adult + v_bf_adult + v_em_adult + v_dx_adult,
								v_sr_child + v_bf_child + v_em_child + v_dx_child,
								v_sr_baby + v_bf_baby + v_em_baby + v_dx_baby,
								v_single);

			v_date := v_date + v_duration;

		END LOOP;

	END;

$$ LANGUAGE plpgsql;
