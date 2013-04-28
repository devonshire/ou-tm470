/* -------------------------------------------------------------- */
/* TM470:  Unconfirmed Booking Report                             */
/* Author: Kevin Peat                                             */
/* Date:   25-Apr-2012                                            */
/* -------------------------------------------------------------- */
CREATE OR REPLACE VIEW unconfirmed_bookings AS

SELECT DISTINCT	bb.name as bandb_name,
						b.id as booking_id,
						g.title || ' ' || g.first_name || ' ' || g.last_name as guest_name,
						g.company,
						b.arrival_date

FROM					booking b,
						booked_room br,
						bed_and_breakfast bb,
						guest g

WHERE					b.status = 'Provisional'
AND					b.id = br.booking_id
AND					br.bb_ref = bb.ref
AND					b.guest = g.id

ORDER BY				bb.name,
						b.arrival_date;

/* -------------------------------------------------------------- */
/* Example of running this report as follows                      */
/* -------------------------------------------------------------- */
SELECT	*
FROM		unconfirmed_bookings;
