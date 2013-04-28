/* ------------------------------------------------------ */
/* TM470:  Postgresql Database Creation Script            */
/* Author: Kevin Peat                                     */
/* ------------------------------------------------------ */
CREATE DATABASE tm470
  WITH OWNER = tm470
       ENCODING = 'LATIN9'
       TABLESPACE = pg_default
       LC_COLLATE = 'en_GB.ISO-8859-15'
       LC_CTYPE = 'en_GB.ISO-8859-15'
       CONNECTION LIMIT = -1;
