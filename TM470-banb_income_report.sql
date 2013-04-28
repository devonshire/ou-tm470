/* -------------------------------------------------------------- */
/* TM470:  Bed and Breakfast Income Report                        */
/* Author: Kevin Peat                                             */
/* Date:   25-Apr-2012                                            */
/* -------------------------------------------------------------- */
CREATE OR REPLACE VIEW bandb_income AS

SELECT		bb.name,
				b.booking_date,
				br.cost
FROM			booking b,
				booked_room br,
				bed_and_breakfast bb
WHERE			b.id = br.booking_id
AND			br.bb_ref = bb.ref
AND			b.status <> 'Cancelled';

/* -------------------------------------------------------------- */
/* Example of running this report as follows                      */
/* -------------------------------------------------------------- */
SELECT		name,
				SUM(cost) as income
FROM			bandb_income
WHERE			booking_date >= '2012-04-01'
AND			booking_date <= '2012-06-30'
GROUP BY 	name
ORDER BY 	income desc;
