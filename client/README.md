# client

Custom Go timing client. Uses httptrace.ClientTrace to record DNS, connect, TLS, TTFB, and total per request, forced to a single protocol per run. Writes JSON to results/.
