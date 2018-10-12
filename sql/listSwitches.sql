--
-- COPYRIGHT (C) 2012, ANTELOPE ENTERPRISES AND JOELLE MASLAK
-- ALL RIGHTS RESERVED
--

--
-- Lists one or all switch records, sorted by switchid
--
-- If a value for i_switch_id, i_hostname, i_descr, or i_snmpcommunity
-- is provided, list only records that match the criteria
--
DROP TYPE type_listSwitches;

-- CREATE TYPE type_listSwitches AS (
-- 	switch_id INT4,
-- 	hostname VARCHAR(255),
-- 	descr VARCHAR(255),
-- 	snmpcommunity VARCHAR(255)
-- );

DROP FUNCTION listSwitches (
	i_switch_id INT4,
	i_hostname VARCHAR(255),
	i_descr VARCHAR(255),
	i_snmpcommunity VARCHAR(255)
);

CREATE OR REPLACE FUNCTION listSwitches (
	i_switch_id INT4,
	i_hostname VARCHAR(255),
	i_descr VARCHAR(255),
	i_snmpcommunity VARCHAR(255)
) RETURNS refcursor AS $$
DECLARE
	ref refcursor;
BEGIN
	OPEN ref FOR
	SELECT	S.switch_id,
		S.hostname,
		S.descr,
		S.snmpcommunity
	FROM	switch S
	WHERE	COALESCE(i_switch_id, S.switch_id) = S.switch_id
	  AND	COALESCE(i_hostname, S.hostname) = S.hostname
	  AND	COALESCE(i_descr, S.descr) = S.descr
	  AND	COALESCE(i_snmpcommunity, S.snmpcommunity) = S.snmpcommunity
	ORDER BY S.switch_id;

	RETURN ref;
END;
$$ LANGUAGE plpgsql;

