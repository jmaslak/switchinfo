--
-- COPYRIGHT (C) 2012, ANTELOPE ENTERPRISES AND JOELLE MASLAK
-- ALL RIGHTS RESERVED
--

--
-- Starts a run (MAC scan)
--
-- Parameters:
--   None
--
-- Returns integer with a value of 1
--
CREATE OR REPLACE FUNCTION startRun() RETURNS INT4 AS $$
DECLARE
BEGIN
	--
	-- Delete from current run
	DELETE FROM active_macs;
	DELETE FROM current_run;

	--
	-- Insert current date into current_run
	INSERT INTO current_run (
		dt
	) VALUES (
		NOW()
	);

	RETURN 1;
END;
$$ LANGUAGE plpgsql;

