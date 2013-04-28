/* -------------------------------------------------------------- */
/* TM470:  Guest Income Report                                    */
/* Author: Kevin Peat                                             */
/* Date:   25-Apr-2012                                            */
/* -------------------------------------------------------------- */
CREATE OR REPLACE VIEW guest_income AS

SELECT		g.title || ' ' || g.first_name || ' ' || g.last_name as guest_name,
				g.company,
				b.booking_date,
				br.cost
FROM			booking b,
				booked_room br,
				guest g
WHERE			b.id = br.booking_id
AND			b.guest = g.id
AND			b.status <> 'Cancelled';

/* -------------------------------------------------------------- */
/* Example of running this report as follows                      */
/* -------------------------------------------------------------- */
SELECT		guest_name,
				company,
				SUM(cost) as income
FROM			guest_income
WHERE			booking_date >= '2012-04-01'
AND			booking_date <= '2012-06-30'
GROUP BY 	guest_name, company
ORDER BY 	income desc;
