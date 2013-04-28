/* -------------------------------------------------------------- */
/* TM470:  Debtors Report                                         */
/* Author: Kevin Peat                                             */
/* Date:   27-Apr-2012                                            */
/* -------------------------------------------------------------- */
CREATE OR REPLACE VIEW debtors AS

SELECT		bb.name as bandb_name,
				b.id as booking_ref,
				g.title || ' ' || g.first_name || ' ' || g.last_name as guest_name,
				g.company,
				b.arrival_date,
				b.departure_date,
				SUM(br.cost) as booking_cost,
				COALESCE((SELECT SUM(amount) FROM room_charge r WHERE r.booking_id = b.id), 0) AS room_charges,
				COALESCE((SELECT SUM(amount) FROM payment p WHERE p.booking_id = b.id), 0) AS payment_recd
FROM			booking b,
				booked_room br,
				bed_and_breakfast bb,
				guest g
WHERE			b.id = br.booking_id
AND			b.guest = g.id
AND			b.status <> 'Cancelled'
AND			br.bb_ref = bb.ref
GROUP BY		bandb_name,
				booking_ref,
				guest_name,
				g.company,
				b.arrival_date,
				b.departure_date
ORDER BY		b.arrival_date,
				booking_ref;

/* -------------------------------------------------------------- */
/* Example of running this report as follows                      */
/* -------------------------------------------------------------- */
SELECT		bandb_name,
				booking_ref,
				guest_name,
				company,
				arrival_date,
				departure_date,
				booking_cost,
				room_charges,
				payment_recd,
				booking_cost + room_charges - payment_recd AS balance_due
FROM			debtors
WHERE			(booking_cost + room_charges - payment_recd) <> 0


