--
-- COPYRIGHT (C) 2012, ANTELOPE ENTERPRISES AND JOELLE MASLAK
-- ALL RIGHTS RESERVED
--

-- 
-- Schema 02
--
-- Add "active" column to switch_info to allow ports to "move"
-- 
-- No defined bridgeport or portindex can be duplicated for "active"
-- records.
-- 

BEGIN TRANSACTION;

-- Add "active" to indicate that the switchport was seen in the most
-- recent scan of the switch
ALTER TABLE switchport
ADD COLUMN active BOOLEAN NOT NULL DEFAULT true;

COMMIT;

