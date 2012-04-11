--
-- COPYRIGHT (C) 2012, ANTELOPE ENTERPRISES AND JOEL C. MASLAK
-- ALL RIGHTS RESERVED
--

-- 
-- Schema 03
--
-- MAC cleanup table
-- 

BEGIN TRANSACTION;

-- mac_id        => From mac table
-- switchport_id => From switchport table
CREATE TABLE active_macs (
	mac_id		INT4		NOT NULL,
	switchport_id	INT4		NOT NULL
);

-- dt => Date of start of run
CREATE TABLE current_run (
	dt		TIMESTAMP	NOT NULL
);

COMMIT;

