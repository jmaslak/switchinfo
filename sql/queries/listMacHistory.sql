--
-- COPYRIGHT (C) 2012, ANTELOPE ENTERPRISES AND JOEL C. MASLAK
-- ALL RIGHTS RESERVED
--

--
-- Lists active MAC addresses, sorted by switch pretty name and
-- then port pretty name.  Filters out uplinks.
--

--
-- Note that the MAC address is encoded in the where clause below.
--

SELECT	S.descr switch_descr,
	SP.descr switchport_descr,
	MH.start_dt,
	CASE	WHEN MH.end_dt = '9999-12-31' THEN NULL
		ELSE MH.end_dt
	END AS end_dt,
	CASE	WHEN MH.end_dt = '9999-12-31' THEN NOW() - MH.start_dt
		ELSE MH.end_dt - MH.start_dt
	END AS duration
FROM	mac_history MH,
	switch S,
	switchport SP,
	mac M
WHERE	MH.mac_id = M.mac_id
  AND	MH.switchport_id = SP.switchport_id
  AND	SP.switch_id = S.switch_id
  AND	SP.uplink = false
  AND	M.mac = 'MAC HERE'
ORDER BY MH.start_dt, S.descr, SP.descr, M.mac, M.descr;

