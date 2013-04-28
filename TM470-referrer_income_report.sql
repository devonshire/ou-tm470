/* -------------------------------------------------------------- */
/* TM470:  Referrer Income Report                                 */
/* Author: Kevin Peat                                             */
/* Date:   25-Apr-2012                                            */
/* -------------------------------------------------------------- */
CREATE OR REPLACE VIEW referrer_income AS

SELECT		b.referrer,
				b.booking_date,
				br.cost
FROM			booking b,
				booked_room br
WHERE			b.id = br.booking_id
AND			b.status <> 'Cancelled';

/* -------------------------------------------------------------- */
/* Example of running this report as follows                      */
/* -------------------------------------------------------------- */
SELECT		referrer,
				SUM(cost) as income
FROM			referrer_income
WHERE			booking_date >= '2012-04-01'
AND			booking_date <= '2012-06-30'
GROUP BY 	referrer
ORDER BY 	income desc;
