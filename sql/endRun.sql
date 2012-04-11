--
-- COPYRIGHT (C) 2012, ANTELOPE ENTERPRISES AND JOEL C. MASLAK
-- ALL RIGHTS RESERVED
--

--
-- Ends a run (MAC scan)
--
-- Marks any records in MAC_HISTORY which are not current as
-- having an end date 1 microsecond ago
--
-- Parameters:
--   None
--
-- Returns integer with a value of 1
--
CREATE OR REPLACE FUNCTION endRun() RETURNS INT4 AS $$
DECLARE
	v_now TIMESTAMP;
BEGIN

	--
	-- Get run time
	SELECT	dt
	INTO	v_now
	FROM	current_run;

	--
	-- Update MACs that no longer are on given ports
	UPDATE	mac_history MH
	   SET	end_dt = v_now - INTERVAL '1 microsecond'
	WHERE	v_now BETWEEN MH.start_dt AND MH.end_dt
	  AND	NOT EXISTS (
			SELECT	AM.mac_id
			FROM	active_macs AM
			WHERE	AM.mac_id = MH.mac_id
			  AND	AM.switchport_id = MH.switchport_id
		);

	DELETE FROM active_macs;
	DELETE FROM current_run;

	RETURN 1;
END;
$$ LANGUAGE plpgsql;

