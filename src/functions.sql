/*
===========================================================================================================================================
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: FUNCTIONS ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
===========================================================================================================================================
*/


/*
=================================================================================================
::::::::::::::::::::::::::::::::::::::::::: LOCATION :::::::::::::::::::::::::::::::::::::::::::
=================================================================================================
*/

/**
=================================================================================================
@function: registerLocation
@param {double precision} lat: latitude
@param {double precision} lon: latitude
@param {varchar} ctry: country
@param {varchar} reg: region
@param {varchar} citnm: city name
@param {varchar} zipc: zip code
@whatdoes: registra una localizacion en la que se ubicara una estacion.
@return: retorna el identificador de la estacion registrada.
=================================================================================================
**/

CREATE OR REPLACE FUNCTION registerLocation(lat double precision, lon double precision, ctry varchar, reg varchar, citnm varchar, zipc varchar)
RETURNS varchar AS $BODY$
DECLARE
	idlocation varchar;
BEGIN
	INSERT INTO location(latitude, longitude, country, region, city, zip_code) 
		VALUES(lat, lon, ctry, reg, citnm, zipc);
	idlocation := (SELECT location.id_location FROM location WHERE location.latitude=lat AND location.longitude=lon);
	
	-- RAISE NOTICE 'idlocation: %', idlocation;
		
	RETURN idlocation;
END; $BODY$ LANGUAGE 'plpgsql';

/*
=================================================================================================
::::::::::::::::::::::::::::::::::::::::::: STATION :::::::::::::::::::::::::::::::::::::::::::
=================================================================================================
*/

/**
=================================================================================================
@function: registerStation
@param {varchar} name: name station
@param {double precision} latitude: latitude
@param {double precision} longitude: latitude
@param {varchar} country: country
@param {varchar} region: region
@param {varchar} cityname: city name
@param {varchar} zipcode: zip code
@whatdoes: registra una estacion en la localizacion indicada.
@return: retorna el identificador de la estacion registrada.
=================================================================================================
**/

CREATE OR REPLACE FUNCTION registerStation(namestation varchar, latitude double precision, longitude double precision, country varchar, region varchar, cityname varchar, zipcode varchar)
RETURNS varchar AS $BODY$
DECLARE
	idlocation varchar;
	idstation varchar;
BEGIN
	idlocation := (SELECT registerLocation(latitude, longitude, country, region, cityname, zipcode));
	
	INSERT INTO station(name_station, id_location)
		VALUES(namestation, idlocation);
 
	idstation := (SELECT station.id_station FROM station WHERE station.name_station=trim(initcap(namestation)));
	RAISE NOTICE 'idstation: %', idstation;
				   
	RETURN idstation;
END; $BODY$ LANGUAGE 'plpgsql';

/*
=================================================================================================
:::::::::::::::::::::::::::::::::::::::::: MEASUREMENT ::::::::::::::::::::::::::::::::::::::::::
=================================================================================================
*/

/**
=================================================================================================
@function: registerMeasurement
@param {double precision} temp: temperature
@param {double precision} hum: humidity
@param {double precision} pres: pressure
@param {double precision} uvrad: ultraviolet radiation
@param {double precision} windvel: wind velocity
@param {double precision} winddir: wind direction
@param {double precision} rainmm: rain milimeters
@param {integer} rainintensity: rain intensity
@param {varchar} namestation: name station
@whatdoes: registra una medicion realizada por una estacion.
@return: void
=================================================================================================
**/

CREATE OR REPLACE FUNCTION registerMeasurement(temp double precision, hum double precision, pres double precision, uvrad double precision, windvel double precision, winddir double precision, rainmm double precision, rainintensity integer, namestation varchar)
RETURNS void AS $BODY$
DECLARE
	idstation station.id_station%TYPE;
BEGIN
	namestation := trim(initcap(namestation));
	idstation := (SELECT station.id_station FROM station WHERE station.name_station=namestation);
	RAISE NOTICE 'idstation: %', idstation;
	
	if (idstation is not null) then
		INSERT INTO measurement(temperature, humidity, pressure, uv_radiation, wind_vel, wind_dir, rain_mm, rain_intensity, id_station)
			VALUES(temp, hum, pres, uvrad, windvel, winddir, rainmm, rainintensity, idstation);
	else
		raise exception 'Revise que la estacion "%" exista', namestation;
	end if;

	RETURN;
END; $BODY$ LANGUAGE 'plpgsql';

/*
=================================================================================================
::::::::::::::::::::::::::::::::::::::::::: FINALUSER :::::::::::::::::::::::::::::::::::::::::::
=================================================================================================
*/

/**
=================================================================================================
@function: getTypeOfUser
@param {varchar} idfinaluser: id finaluser
@whatdoes: devuelve el tipo de usuario recibido como parametro,
		   los valores devueltos son ADMINISTRATOR o CLIENT.
@return: varchar
=================================================================================================
**/

CREATE OR REPLACE FUNCTION getTypeOfUser(idfinaluser varchar)
RETURNS varchar AS $BODY$
DECLARE
	ISCLIENT varchar := 'CLIENT';
	ISADMINISTRATOR varchar := 'ADMINISTRATOR';
	clientSelected varchar;
	administratorSelected varchar;
BEGIN
	clientSelected := (SELECT client.id_client FROM client WHERE client.id_finaluser=idfinaluser);
	-- RAISE NOTICE 'clientSelected: %', clientSelected;
	administratorSelected := (SELECT administrator.id_administrator FROM administrator WHERE administrator.id_finaluser=idfinaluser);
	-- RAISE NOTICE 'administratorSelected: %', administratorSelected;
	if (clientSelected is not null) then
		return ISCLIENT;
	end if;
	
	if (administratorSelected is not null) then
		return ISADMINISTRATOR;
	end if;
	
	if (clientSelected is null AND administratorSelected is null) then
		raise exception 'Usuario % no registrado', idfinaluser;
	end if;
END; $BODY$ LANGUAGE 'plpgsql';

/**
=================================================================================================
@function: getWeatherdataBetweenDates
@param {double precision} lat: latitude
@param {double precision} lon: longitude
@param {varchar} startdate: start date (YYYY-MM-DD HH:MM:SS.mm)
@param {varchar} enddate: end date (YYYY-MM-DD HH:MM:SS.mm)
@whatdoes: devuelve todas las mediciones registradas entre fecha de inicio y de fin en una 
		   determinada geolocalizacion.
@return: record
=================================================================================================
**/

CREATE OR REPLACE FUNCTION getWeatherdataBetweenDates(idstation varchar, startdate varchar, enddate varchar)
RETURNS SETOF measurement AS $BODY$
DECLARE
	weatherdata measurement%ROWTYPE;
	stationlocated station.id_station%TYPE;
BEGIN
	stationlocated := (SELECT station.id_station FROM station WHERE station.id_station=idstation);
	raise notice 'idstation: %', idstation;
	
	if (stationlocated is null) then
		raise exception 'No poseemos ninguna estacion con el identificador: %', idstation;
	end if;
	
	if (stationlocated is not null) then
		for weatherdata in (SELECT * FROM measurement 
					  	WHERE measurement.id_station=stationlocated 
					  	AND measurement.date_measurement 
					  	BETWEEN TO_TIMESTAMP(startdate, 'YYYY-MM-DD HH24:MI:SS')
					  	AND  TO_TIMESTAMP(enddate, 'YYYY-MM-DD HH24:MI:SS'))
		loop
			return next weatherdata;
		end loop;
	end if;
	
	if(weatherdata is null) then
		raise exception 'No poseemos mediciones en el intervalo de fechas especificado [%, %]', startdate, enddate;
	end if;
	
	RETURN;
END; $BODY$ LANGUAGE 'plpgsql';

/**
=================================================================================================
@function: getWeatherdataByStationId
@param {varchar} idstation: id station
@whatdoes: devuelve la ultima medicion registrada por una determinada estacion.
@return: record
=================================================================================================
**/

CREATE OR REPLACE FUNCTION getWeatherdataByStationId(idstation varchar)
RETURNS SETOF measurement AS $BODY$
DECLARE
	weatherdata measurement%ROWTYPE;
	stationlocated station.id_station%TYPE;
BEGIN
	stationlocated := (SELECT station.id_location FROM station WHERE station.id_station=idstation);
	-- raise notice 'stationlocated: %', stationlocated;
	if (stationlocated is null) then
		raise exception 'No poseemos datos de mediciones para este id: % de estacion', idstation;
	else
		for weatherdata in (SELECT * FROM measurement 
						WHERE measurement.id_station=idstation 
						ORDER BY measurement.date_measurement 
						DESC LIMIT 1)
		loop
			return next weatherdata;
		end loop;
	end if;
					
	RETURN;
END; $BODY$ LANGUAGE 'plpgsql';

/**
=================================================================================================
@function: getWeatherdataByPlace
@param {varchar} regionname: region
@param {varchar} cityname: city name
@whatdoes: devuelve la ultima medicion realizada en una region y ciudad.
@return: record
=================================================================================================
**/

CREATE OR REPLACE FUNCTION getWeatherdataByPlace(regionname varchar, cityname varchar)
RETURNS SETOF measurement AS $BODY$
DECLARE
	weatherdata measurement%ROWTYPE;
	stationlocated station.id_station%TYPE;
	idlocationreq location.id_location%TYPE;
BEGIN
	regionname := trim(initcap(regionname));
	cityname := trim(initcap(cityname));
	idlocationreq := (SELECT location.id_location FROM location 
					  	WHERE location.region=regionname AND location.city=cityname
					  	ORDER BY location.id_location ASC LIMIT 1);
	-- raise notice 'idlocation: %', idlocationreq;
	
	if (idlocationreq is null) then
		raise exception 'No poseemos datos de mediciones en la region % y ciudad %.', regionname, cityname;
	else
		stationlocated := (SELECT station.id_station FROM station WHERE station.id_location=idlocationreq);
		-- raise notice 'stationlocated: %', stationlocated;
		
		for weatherdata in (SELECT * FROM measurement 
					WHERE measurement.id_station=stationlocated 
					ORDER BY measurement.date_measurement 
					DESC LIMIT 1)
		loop
			return next weatherdata;
		end loop;
	end if;
	
	RETURN;
END; $BODY$ LANGUAGE 'plpgsql';

/*
=================================================================================================
@function: getWeatherdataByGeolocation
@param {double precision} lat: latitude
@param {double precision} lon: longitude
@whatdoes: devuelve la ultima medicion registradas en una determinada geolocalizacion.
@return: record
=================================================================================================
*/

CREATE OR REPLACE FUNCTION getWeatherdataByGeolocation(lat double precision, lon double precision)
RETURNS SETOF measurement AS $BODY$
DECLARE
	weatherdata measurement%ROWTYPE;
	stationlocated station.id_station%TYPE;
	idlocationreq location.id_location%TYPE;
BEGIN
	idlocationreq := (SELECT location.id_location FROM location 
					  	WHERE location.latitude=lat AND location.longitude=lon);
	-- raise notice 'idlocationreq: %', idlocationreq;
	
	if (idlocationreq is null) then
		raise exception 'No poseemos datos de mediciones en la latitude: % y longitude: %', lat, lon;
	else
		stationlocated := (SELECT station.id_station FROM station WHERE station.id_location=idlocationreq);
		-- raise notice 'stationlocated: %', stationlocated;
		
		for weatherdata in (SELECT * FROM measurement 
					WHERE measurement.id_station=stationlocated 
					ORDER BY measurement.date_measurement 
					DESC LIMIT 1)
		loop
			return next weatherdata;
		end loop;
	end if;
	
	RETURN;
END; $BODY$ LANGUAGE 'plpgsql';

/*
=================================================================================================
@function: getWeatherdataByZipCode
@param {varchar} zipcode: zip code
@whatdoes: devuelve la ultima medicion realizada en una region segun su codigo de area.
@return: record
=================================================================================================
*/

CREATE OR REPLACE FUNCTION getWeatherdataByZipCode(zipcode varchar)
RETURNS SETOF measurement AS $BODY$
DECLARE
	weatherdata measurement%ROWTYPE;
	stationlocated station.id_station%TYPE;
	idlocationreq location.id_location%TYPE;
BEGIN
	zipcode := trim(upper(zipcode));
	idlocationreq := (SELECT location.id_location FROM location 
					  	WHERE location.zip_code=zipcode
					  	ORDER BY location.id_location ASC LIMIT 1);
	-- raise notice 'idlocationreq: %', idlocationreq;
	
	if (idlocationreq is null) then
		raise exception 'No poseemos datos de mediciones en la ciudad con el zipcode: %.', zipcode;
	else
		stationlocated := (SELECT station.id_station FROM station WHERE station.id_location=idlocationreq);
		-- raise notice 'stationlocated: %', stationlocated;
		
		for weatherdata in (SELECT * FROM measurement 
					WHERE measurement.id_station=stationlocated 
					ORDER BY measurement.date_measurement 
					DESC LIMIT 1)
		loop
			return next weatherdata;
		end loop;
	end if;
	
	RETURN;
END; $BODY$ LANGUAGE 'plpgsql';

/*
=================================================================================================
@function: getStations
@whatdoes: devuelve todas las estaciones existentes.
@return: stationdata(id_station varchar, name_station varchar, fail bool, created_at timestamp, 
latitude double precision, 
		 longitude double precision, country varchar, region varchar, city varchar, 
		 zip_code varchar)
=================================================================================================
*/

CREATE OR REPLACE FUNCTION getStations(amount integer default 0)
RETURNS SETOF record AS $BODY$
DECLARE
	stationdata record%TYPE;
BEGIN
	for stationdata in (SELECT station.id_station, station.name_station, 
						station.fail, station.created_at, location.latitude, 
						location.longitude, location.country, location.region, 
						location.city, location.zip_code
 			FROM station, location
				WHERE station.id_location=location.id_location 
					ORDER BY station.name_station ASC
					   LIMIT all OFFSET amount)
	loop
		return next stationdata;
	end loop;
	
	if (stationdata is null) then
		raise exception 'No poseemos estaciones.';
	end if;
	
	RETURN;
END; $BODY$ LANGUAGE 'plpgsql';

/*
=================================================================================================
@function: getStationdataBetweenDates
@param {varchar} startdate: start date (YYYY-MM-DD HH:MM:SS.mm)
@param {varchar} enddate: end date (YYYY-MM-DD HH:MM:SS.mm)
@param {integer} amount: amount rows
@whatdoes: devuelve todas las estaciones creadas en un intervalo de fechas [startdate; enddate].
@return: stationdata(id_station varchar, name_station varchar, fail bool, created_at timestamp, 
		 latitude double precision, longitude double precision, country varchar, region varchar, 
		 city varchar, zip_code varchar)
=================================================================================================
*/

CREATE OR REPLACE FUNCTION getStationdataBetweenDates(startdate varchar, enddate varchar, amount integer default 10)
RETURNS SETOF record AS $BODY$
DECLARE
	stationdata record%TYPE;
BEGIN
	for stationdata in (SELECT station.id_station, station.name_station, 
						station.fail, station.created_at, location.latitude, 
						location.longitude, location.country, location.region, 
						location.city, location.zip_code
 			FROM station, location
				WHERE station.id_location=location.id_location 
					AND station.created_at 
						BETWEEN TO_TIMESTAMP(startdate, 'YYYY-MM-DD HH24:MI:SS') 
							AND  TO_TIMESTAMP(enddate, 'YYYY-MM-DD HH24:MI:SS') 
						ORDER BY station.created_at ASC
						LIMIT amount)
	loop
		return next stationdata;
	end loop;
	
	if (stationdata is null) then
		raise exception 'No poseemos estaciones creadas en el intervalo de fechas [%; %].', startdate, enddate;
	end if;
	
	RETURN;
END; $BODY$ LANGUAGE 'plpgsql';

/*
=================================================================================================
@function: getStationdataById
@param {varchar} idstation: id station
@whatdoes: devuelve la estacion con el id especificado.
@return: stationdata(id_station varchar, name_station varchar, fail bool, created_at timestamp, 
		 latitude double precision, longitude double precision, country varchar, region varchar, 
		 city varchar, zip_code varchar)
=================================================================================================
*/

CREATE OR REPLACE FUNCTION getStationdataById(idstation varchar)
RETURNS SETOF record AS $BODY$
DECLARE
	stationdata record%TYPE;
BEGIN
	for stationdata in (SELECT station.id_station, station.name_station, 
						station.fail, station.created_at, location.latitude, 
						location.longitude, location.country, location.region, 
						location.city, location.zip_code
 			FROM station, location
				WHERE station.id_station=idstation 
					AND station.id_location=location.id_location)
	loop
		return next stationdata;
	end loop;
	
	if (stationdata is null) then
		raise exception 'No poseemos estaciones con el id: % especificado.', idstation;
	end if;
	
	RETURN;
END; $BODY$ LANGUAGE 'plpgsql';

/*
=================================================================================================
@function: getStationdataByPlace
@param {varchar} regionname: region name
@param {varchar} cityname: city name
@param {integer} amount: amount rows
@whatdoes: devuelve todas las estaciones localizadas en la region y ciudad especificada.
@return: stationdata(id_station varchar, name_station varchar, fail bool, created_at timestamp, 
		 latitude double precision, longitude double precision, country varchar, region varchar, 
		 city varchar, zip_code varchar)
=================================================================================================
*/

CREATE OR REPLACE FUNCTION getStationdataByPlace(regionname varchar, cityname varchar, amount integer default 10)
RETURNS SETOF record AS $BODY$
DECLARE
	stationdata record%TYPE;
BEGIN
	regionname := trim(initcap(regionname));
	cityname := trim(initcap(cityname));
	for stationdata in (SELECT station.id_station, station.name_station, 
						station.fail, station.created_at, location.latitude, 
						location.longitude, location.country, location.region, 
						location.city, location.zip_code
 			FROM station, location
				WHERE station.id_location=location.id_location 
					AND location.region=regionname
					AND location.city=cityname
						ORDER BY station.created_at ASC
						LIMIT amount)
	loop
		return next stationdata;
	end loop;
	
	if (stationdata is null) then
		raise exception 'No poseemos estaciones ubicadas en la region % y ciudad %.', regionname, cityname;
	end if;
	
	RETURN;
END; $BODY$ LANGUAGE 'plpgsql';

/*
=================================================================================================
@function: getStationdataByGeolocation
@param {double precision} lat: latitude
@param {double precision} lon: longitude
@whatdoes: devuelve la estacion localizazda en la geolocalizacion especificada.
@return: stationdata(id_station varchar, name_station varchar, fail bool, created_at timestamp, 
		 latitude double precision, longitude double precision, country varchar, region varchar, 
		 city varchar, zip_code varchar)
=================================================================================================
*/

CREATE OR REPLACE FUNCTION getStationdataByGeolocation(lat double precision, lon double precision)
RETURNS SETOF record AS $BODY$
DECLARE
	stationdata record%TYPE;
BEGIN
	for stationdata in (SELECT station.id_station, station.name_station, 
						station.fail, station.created_at, location.latitude, 
						location.longitude, location.country, location.region, 
						location.city, location.zip_code
 			FROM station, location
				WHERE station.id_location=location.id_location 
					AND location.latitude=lat
					AND location.longitude=lon)
	loop
		return next stationdata;
	end loop;
	
	if (stationdata is null) then
		raise exception 'No poseemos ninguna estacion ubicada en las coordenadas latitude: % ; longitude: %.', lat, lon;
	end if;
	
	RETURN;
END; $BODY$ LANGUAGE 'plpgsql';

/*
=================================================================================================
@function: getStationdataByZipcode
@param {varchar} zipcode: zip code
@param {integer} amount: amount rows
@whatdoes: devuelve todas las estaciones localizadas en la region con el codigo de area especificado.
@return: stationdata(id_station varchar, name_station varchar, fail bool, created_at timestamp, 
		 latitude double precision, longitude double precision, country varchar, region varchar, 
		 city varchar, zip_code varchar)
=================================================================================================
*/

CREATE OR REPLACE FUNCTION getStationdataByZipcode(zipcode varchar, amount integer default 10)
RETURNS SETOF record AS $BODY$
DECLARE
	stationdata record%TYPE;
BEGIN
	zipcode := trim(upper(zipcode));
	for stationdata in (SELECT station.id_station, station.name_station, 
						station.fail, station.created_at, location.latitude, 
						location.longitude, location.country, location.region, 
						location.city, location.zip_code
 			FROM station, location
				WHERE station.id_location=location.id_location 
					AND location.zip_code=zipcode
						ORDER BY station.created_at ASC
						LIMIT amount)
	loop
		return next stationdata;
	end loop;
	
	if (stationdata is null) then
		raise exception 'No poseemos estaciones ubicadas la region con el zipcode %.', zipcode;
	end if;
	
	RETURN;
END; $BODY$ LANGUAGE 'plpgsql';

/*
=================================================================================================
::::::::::::::::::::::::::::::::::::::::: ADMINISTRATOR :::::::::::::::::::::::::::::::::::::::::
=================================================================================================
*/

/**
=================================================================================================
function: clientsSuscribedAtPlan(planname varchar)
@param {varchar} planname: plan name
@whatdoes: devuelve todos los usuarios suscriptosa un determinado plan.
@return: record
=================================================================================================
**/

CREATE OR REPLACE FUNCTION clientsSuscribedAtPlan(planname varchar)
RETURNS SETOF record AS $BODY$
DECLARE clients record%TYPE;
BEGIN
	planname := trim(initcap(planname));
	for clients in (SELECT client.id_client, finaluser.username, finaluser.email
						FROM client, finaluser 
							WHERE client.suscribed_to_plan=planname
								and client.id_finaluser=finaluser.id_finaluser)
	LOOP
		RETURN NEXT clients;
	END LOOP;

	if(clients is null) THEN
		RAISE EXCEPTION 'No existen clientes suscriptos al plan: %.', planname;
	END IF;
	RETURN;
END;
$BODY$ LANGUAGE plpgsql;

/*
=================================================================================================
:::::::::::::::::::::::::::::::::::::::::::: CLIENT ::::::::::::::::::::::::::::::::::::::::::::
=================================================================================================
*/

/**
=================================================================================================
@function: upgradePlan
@param {varchar} idclient: id client
@param {varchar} plantosuscribe: plan to suscribe
@whatdoes: actualiza el plan actual al que esta suscripto el cliente. Incluye: 
		   actualizar suscribed_to_plan, acualizar available_consults.
@return: void
=================================================================================================
**/

CREATE OR REPLACE FUNCTION upgradePlan(idclient varchar, plantosuscribe varchar) 
RETURNS void AS $BODY$
DECLARE
	planselected plan%ROWTYPE;
	currentplan varchar;
BEGIN	
	plantosuscribe := trim(initcap(plantosuscribe));
	planselected := (SELECT plan FROM plan WHERE plan.description=plantosuscribe);
	if (planselected is null) then
		raise exception 'El plan % no esta disponible.', plantosuscribe;
	end if;
	
	currentplan := (SELECT client.suscribed_to_plan FROM client WHERE client.id_client=idclient);
	if(currentplan=plantosuscribe) then
		raise exception 'Usted ya posee el plan %.', plantosuscribe;
	end if;
	
	if (planselected is not null AND idclient is not null) then
		UPDATE client SET 
			suscribed_to_plan=planselected.description,
			available_consults=planselected.amount_consults
				WHERE client.id_client=idclient;
	end if;

	RETURN;
END; $BODY$ LANGUAGE plpgsql;

/**
=================================================================================================
@function: generateApikey
@param {varchar} idclient: id client
@param {varchar} apikeyname: plan to suscribe
@whatdoes: genera una nueva apikey y la asocia al cliente especificado.
@return: void
=================================================================================================
**/

CREATE OR REPLACE FUNCTION generateApikey(idclient varchar, apikeyname varchar default 'Default') 
RETURNS void AS $BODY$
DECLARE
	apikeyid varchar;
BEGIN
	apikeyname := trim(initcap(apikeyname));
	if (idclient is not null AND apikeyname is not null) then
		INSERT INTO apikey(id_apikey, name_apikey, id_client) VALUES(gen_random_uuid(), apikeyname, idclient);
	else
		raise exception 'Cliente % no registrado.', idclient;
	end if;
	
	RETURN;
END; $BODY$ LANGUAGE plpgsql;

/*
=================================================================================================
::::::::::::::::::::::::::::::::::::::::: QUERYHISTORY :::::::::::::::::::::::::::::::::::::::::
=================================================================================================
*/

/**
=================================================================================================
@function: saveInQueryHistory
@param {varchar} idcurrentuser: email
@whatdoes: añade un registro en el historial de consultas.
@return: void
=================================================================================================
**/

CREATE OR REPLACE FUNCTION saveInQueryHistory(idcurrentclient varchar)
RETURNS void AS $BODY$
DECLARE
	lastqueryhistory queryhistory%ROWTYPE;
	datelastquery date;
	currentdate date;
BEGIN
	lastqueryhistory := (SELECT queryhistory
		FROM queryhistory WHERE queryhistory.id_client=idcurrentclient 
			ORDER BY queryhistory.date_query DESC LIMIT 1);
	-- raise notice 'lastqueryhistory: %', lastqueryhistory; 
	
	if (lastqueryhistory is null) then
		raise exception 'Corrobore que el idcurrentclient: "%" sea el correcto.', idcurrentclient;
	end if;
	
	datelastquery := lastqueryhistory.date_query::date;
	-- raise notice 'datelastquery: %', datelastquery;
	
	currentdate := (SELECT current_timestamp::date);
	-- raise notice 'currentdate: %', currentdate;

	if (datelastquery = currentdate) then
		UPDATE queryhistory SET amount_consults=amount_consults+1
			WHERE queryhistory.id_qh=lastqueryhistory.id_qh;
	end if;
	
	if (datelastquery != currentdate) then
		INSERT INTO queryhistory(amount_consults, id_client) VALUES(1, idcurrentclient);
	end if;
	RETURN;
END; $BODY$ LANGUAGE 'plpgsql';
