--
-- COPYRIGHT (C) 2012, ANTELOPE ENTERPRISES AND JOELLE MASLAK
-- ALL RIGHTS RESERVED
--

-- 
-- Schema 04
--
-- Correct unique keys on mac_history table
-- 

BEGIN TRANSACTION;

ALTER TABLE mac_history
DROP CONSTRAINT mac_history_pkey;

ALTER TABLE mac_history
ADD PRIMARY KEY (mac_id, start_dt, switchport_id);

ALTER TABLE mac_history
DROP CONSTRAINT mac_history_AK1;

ALTER TABLE mac_history
ADD CONSTRAINT mac_history_AK1 UNIQUE (mac_id, end_dt, switchport_id);

COMMIT;

