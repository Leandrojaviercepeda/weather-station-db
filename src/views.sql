/*
===========================================================================================================================================
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: VIEWS ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
===========================================================================================================================================
*/


/*
=================================================================================================
::::::::::::::::::::::::::::::::::::::::::: LOCATION :::::::::::::::::::::::::::::::::::::::::::
=================================================================================================
*/

/*
=================================================================================================
view: locationsMoreThanOneStation
whatdoes: devuelve las localidades que tienen mas de una estación.
=================================================================================================
*/

CREATE OR REPLACE VIEW locationsMoreThanOneStation  AS
(
 SELECT DISTINCT l.country, l.region, l.city FROM location l, location lcopy, station s
	WHERE l.id_location=s.id_location AND l.id_location!=lcopy.id_location AND l.latitude!=lcopy.latitude AND l.longitude!=lcopy.longitude
		AND l.country=lcopy.country AND l.region=lcopy.region AND l.city=lcopy.city
);

/*
=================================================================================================
::::::::::::::::::::::::::::::::::::::::::: STATION :::::::::::::::::::::::::::::::::::::::::::
=================================================================================================
*/

/*
=================================================================================================
views: stationsThatFailed
whatdoes: Devuelve todas las estaciones que fallaron al menos una vez.
=================================================================================================
*/

CREATE OR REPLACE VIEW stationsThatFailed AS
(
 SELECT DISTINCT m.id_station
   FROM measurement m
  WHERE m.temperature is null OR m.humidity is null OR m.pressure is null OR m.uv_radiation is null OR m.wind_vel is null 
	OR m.wind_dir is null OR m.rain_mm is null OR m.rain_intensity is null
);

/*
=================================================================================================
view: stationFailuredDate
whatdoes: Devuelve todas las estaciones que fallaron al menos una vez y la fecha correspondiente.
=================================================================================================
*/

CREATE OR REPLACE VIEW stationFailuredDate AS
(
 SELECT m.id_station, m.date_measurement::date
   FROM measurement m
  WHERE m.temperature is null OR m.humidity is null OR m.pressure is null OR m.uv_radiation is null OR m.wind_vel is null 
	OR m.wind_dir is null OR m.rain_mm is null OR m.rain_intensity is null
);

/*
=================================================================================================
::::::::::::::::::::::::::::::::::::::::: ADMINISTRATOR :::::::::::::::::::::::::::::::::::::::::
=================================================================================================
*/

/*
=================================================================================================
view: customersConsultLastWeek
whatdoes: Devuelve todos los clientes que hicieron consultas la ultima semana.
=================================================================================================
*/

CREATE OR REPLACE VIEW customersConsultLastWeek AS
(
 SELECT qh.id_client
 FROM client c, queryhistory qh
 WHERE c.id_client = qh.id_client 
	AND qh.date_query::date > (current_date::date - integer '7') AND qh.date_query::date < (current_date::date)
);