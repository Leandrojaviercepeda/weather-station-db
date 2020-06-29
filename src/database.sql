BEGIN;

/*
===========================================================================================================================================
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: TABLES ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
===========================================================================================================================================
*/


/*
=================================================================================================
:::::::::::::::::::::::::::::::::::::::::: EXTENSIONS ::::::::::::::::::::::::::::::::::::::::::
=================================================================================================
*/
CREATE EXTENSION IF NOT EXISTS pgcrypto;

/**
=================================================================================================
@function: generateRandomId
@param {integer} lenght: lenght of string
@whatdoes: genera una cadena de caracteres aleatorios que puede utilizarse como identificador.
@return: retorna una cadena de caracteres del tamaño especificado.
=================================================================================================
**/

CREATE OR REPLACE FUNCTION generateRandomId(lenght integer default 30)
RETURNS varchar AS $BODY$
DECLARE
	identificator varchar;
	idlimit integer default 30;
BEGIN
	if (lenght between 0 and idlimit) then
		identificator := (SUBSTRING(REPLACE(cast(gen_random_uuid() as text),'-', '') from 0 for lenght+1));
	else
		raise exception 'El largo minimo es 0 y el maximo es %.', idlimit;
	end if;
	RETURN identificator;
END; $BODY$ LANGUAGE 'plpgsql';

/*
=================================================================================================
::::::::::::::::::::::::::::::::::::::::::: LOCATION :::::::::::::::::::::::::::::::::::::::::::
=================================================================================================
*/

CREATE TABLE public.location
(
    id_location varchar UNIQUE DEFAULT generateRandomId(15),
    latitude double precision UNIQUE NOT NULL,
    longitude double precision UNIQUE NOT NULL,
    country varchar NOT NULL,
	region varchar NOT NULL,
    city varchar NOT NULL,
    zip_code varchar(4) NOT NULL,
    CONSTRAINT PK_location PRIMARY KEY (id_location)
);

/*
=================================================================================================
::::::::::::::::::::::::::::::::::::::::::: STATION :::::::::::::::::::::::::::::::::::::::::::
=================================================================================================
*/

CREATE TABLE public.station
(
    id_station varchar UNIQUE DEFAULT generateRandomId(15),
    name_station varchar UNIQUE NOT NULL,
    fail boolean DEFAULT false,
    created_at timestamp (0) WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    id_location varchar NOT NULL,
    CONSTRAINT PK_station PRIMARY KEY (id_station),
    CONSTRAINT FK_location FOREIGN KEY (id_location)
        REFERENCES public.location (id_location)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

/*
=================================================================================================
:::::::::::::::::::::::::::::::::::::::::: MEASUREMENT ::::::::::::::::::::::::::::::::::::::::::
=================================================================================================
*/

CREATE TABLE public.measurement
(
    id_measurement varchar UNIQUE DEFAULT generateRandomId(15),
    date_measurement timestamp (0) WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    temperature double precision,
    humidity double precision,
    pressure double precision,
    uv_radiation double precision,
    wind_vel double precision,
    wind_dir double precision,
    rain_mm double precision,
    rain_intensity integer,
    id_station varchar NOT NULL,
    CONSTRAINT PK_measurement PRIMARY KEY (id_measurement),
    CONSTRAINT FK_station FOREIGN KEY (id_station)
        REFERENCES public.station (id_station)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

/*
=================================================================================================
::::::::::::::::::::::::::::::::::::::::::::: PLAN :::::::::::::::::::::::::::::::::::::::::::::
=================================================================================================
*/

CREATE TABLE public.plan(
    description varchar UNIQUE NOT NULL DEFAULT 'Basic',
    price double precision NOT NULL,
    amount_consults integer NOT NULL,
	historical_data varchar NOT NULL,
	CONSTRAINT PK_plan PRIMARY KEY (description)
);

/*
=================================================================================================
::::::::::::::::::::::::::::::::::::::::::: FINALUSER :::::::::::::::::::::::::::::::::::::::::::
=================================================================================================
*/

CREATE TABLE public.finaluser(
    id_finaluser varchar UNIQUE DEFAULT generateRandomId(15),
    email varchar UNIQUE NOT NULL CHECK(email LIKE('%@%.%')),
    username varchar,
    profile_picture varchar,
    birthdate date CHECK((date_part('year', age(birthdate)) >= 18) AND (date_part('year', age(birthdate)) <= 122)),
    CONSTRAINT PK_user PRIMARY KEY (id_finaluser)
);

/*
=================================================================================================
::::::::::::::::::::::::::::::::::::::::: ADMINISTRATOR :::::::::::::::::::::::::::::::::::::::::
=================================================================================================
*/

CREATE TABLE public.administrator(
    id_administrator varchar UNIQUE DEFAULT generateRandomId(15),
    id_finaluser varchar NOT NULL,
    CONSTRAINT PK_administrator PRIMARY KEY (id_administrator),
    CONSTRAINT FK_user FOREIGN KEY (id_finaluser) REFERENCES public.finaluser(id_finaluser)
    ON UPDATE CASCADE
    ON DELETE CASCADE
);

/*
=================================================================================================
:::::::::::::::::::::::::::::::::::::::::::: CLIENT ::::::::::::::::::::::::::::::::::::::::::::
=================================================================================================
*/

CREATE TABLE public.client(
    id_client varchar UNIQUE DEFAULT generateRandomId(15),
    available_consults integer NOT NULL,
    suscribed_to_plan varchar NOT NULL,
    id_finaluser varchar NOT NULL,
    CONSTRAINT PK_client PRIMARY KEY (id_client),
    CONSTRAINT FK_plan FOREIGN KEY (suscribed_to_plan) REFERENCES public.plan(description),
    CONSTRAINT FK_finaluser FOREIGN KEY (id_finaluser) REFERENCES public.finaluser(id_finaluser)
    ON UPDATE CASCADE
    ON DELETE CASCADE
);

/*
=================================================================================================
:::::::::::::::::::::::::::::::::::::::::::: APIKEY ::::::::::::::::::::::::::::::::::::::::::::
=================================================================================================
*/

CREATE TABLE public.apikey(
    id_apikey varchar UNIQUE DEFAULT generateRandomId(30),
    name_apikey varchar DEFAULT ('Default'),
	id_client varchar NOT NULL,
    CONSTRAINT PK_apikey PRIMARY KEY (id_apikey),
	CONSTRAINT FK_client FOREIGN KEY (id_client) REFERENCES public.client(id_client)
	ON UPDATE CASCADE
    ON DELETE CASCADE
);

/*
=================================================================================================
::::::::::::::::::::::::::::::::::::::::: QUERYHISTORY :::::::::::::::::::::::::::::::::::::::::
=================================================================================================
*/

CREATE TABLE public.queryhistory(
    id_qh varchar UNIQUE DEFAULT generateRandomId(15),
    amount_consults integer DEFAULT 0,
    date_query timestamp (0) WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    id_client varchar NOT NULL,
    CONSTRAINT PK_queryhistory PRIMARY KEY (id_qh),
    CONSTRAINT FK_client FOREIGN KEY (id_client) REFERENCES public.client(id_client)
    ON UPDATE CASCADE
    ON DELETE CASCADE
);


/*
===========================================================================================================================================
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: ROLES ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
===========================================================================================================================================
*/

/*
=================================================================================================
:::::::::::::::::::::::::::::::::::::::::: DEVELOPPER ::::::::::::::::::::::::::::::::::::::::::
=================================================================================================
*/

CREATE ROLE developper WITH SUPERUSER CREATEDB CREATEROLE LOGIN REPLICATION ENCRYPTED PASSWORD 'developper';
GRANT ALL PRIVILEGES ON SCHEMA PUBLIC TO developper;

/*
=================================================================================================
::::::::::::::::::::::::::::::::::::::::::: FINALUSER :::::::::::::::::::::::::::::::::::::::::::
=================================================================================================
*/

CREATE ROLE finaluser WITH NOINHERIT LOGIN REPLICATION ENCRYPTED PASSWORD 'finaluser';
GRANT SELECT ON TABLE location, station, measurement, finaluser TO finaluser;
GRANT SELECT, UPDATE, DELETE ON TABLE finaluser TO finaluser;

/*
=================================================================================================
::::::::::::::::::::::::::::::::::::::::: ADMINISTRATOR :::::::::::::::::::::::::::::::::::::::::
=================================================================================================
*/

CREATE ROLE admin WITH SUPERUSER NOINHERIT LOGIN REPLICATION ENCRYPTED PASSWORD 'admin';
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE location, station, measurement, finaluser, plan, apikey, client, queryhistory TO admin;
GRANT SELECT ON TABLE administrator to admin;

/*
=================================================================================================
:::::::::::::::::::::::::::::::::::::::::::: CLIENT ::::::::::::::::::::::::::::::::::::::::::::
=================================================================================================
*/

CREATE ROLE client WITH NOINHERIT LOGIN REPLICATION ENCRYPTED PASSWORD 'client';
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE apikey, finaluser, client TO client;
GRANT SELECT, INSERT, UPDATE ON TABLE queryhistory TO client;
GRANT SELECT ON TABLE plan TO client;


/*
===========================================================================================================================================
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: TRIGERS :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
===========================================================================================================================================
*/


/*
=================================================================================================
::::::::::::::::::::::::::::::::::::::::::: LOCATION :::::::::::::::::::::::::::::::::::::::::::
=================================================================================================
*/

/*
=================================================================================================
trigger: capitalizeLocation()
whatdoes: capitaliza los atributos country, region, city de la relacion location.
=================================================================================================
*/

CREATE OR REPLACE FUNCTION capitalizeLocation() RETURNS TRIGGER AS $funcemp$
BEGIN
	new.country := trim(initcap(new.country));
	new.region := trim(initcap(new.region));
	new.city := trim(initcap(new.city));
	RETURN NEW;
END; $funcemp$ LANGUAGE plpgsql;

CREATE TRIGGER capitalizeLocation BEFORE INSERT OR UPDATE ON location FOR EACH ROW EXECUTE PROCEDURE capitalizeLocation();

/*
=================================================================================================
trigger: removeLocationAfterStation()
whatdoes: luego de eliminar una estacion, elimina la localizacion correspondiente a la misma.
=================================================================================================
*/

CREATE OR REPLACE FUNCTION removeLocationAfterStation() RETURNS TRIGGER AS $funcemp$
BEGIN
	DELETE FROM location WHERE location.id_location=OLD.id_location;
	RETURN NEW;
END; $funcemp$ LANGUAGE plpgsql;

CREATE TRIGGER removeLocationAfterStation AFTER DELETE ON station FOR EACH ROW EXECUTE PROCEDURE removeLocationAfterStation();

/*
=================================================================================================
::::::::::::::::::::::::::::::::::::::::::: STATION :::::::::::::::::::::::::::::::::::::::::::
=================================================================================================
*/

/*
=================================================================================================
trigger: capitalizeStation()
whatdoes: capitaliza el atributo name_station de la relacion station.
=================================================================================================
*/

CREATE OR REPLACE FUNCTION capitalizeStation() RETURNS TRIGGER AS $funcemp$
BEGIN
	new.name_station := trim(initcap(new.name_station));
	RETURN NEW;
END; $funcemp$ LANGUAGE plpgsql;

CREATE TRIGGER capitalizeStation BEFORE INSERT OR UPDATE ON station FOR EACH ROW EXECUTE PROCEDURE capitalizeStation();

/*
=================================================================================================
trigger: stationStatusControl()
whatdoes: controla el estado fail de la estacion. 
Si una variable de medicion es nula o vacia se asume una falla.
=================================================================================================
*/

CREATE OR REPLACE FUNCTION stationStatusControl() RETURNS TRIGGER AS $funcemp$
DECLARE
	fail bool;
BEGIN
	fail := (SELECT station.fail FROM station WHERE station.id_station = NEW.id_station);
	
	if ((new.temperature is null) or (new.humidity is null) or (new.pressure is null)
			or (new.uv_radiation is null) or (new.wind_vel is null) or (new.wind_dir is null)
			or (new.rain_mm is null) or (new.rain_intensity is null)) then
		UPDATE station SET fail=true WHERE station.id_station = new.id_station;
	else
		UPDATE station SET fail=false WHERE station.id_station = NEW.id_station;
	end if;
    
	RETURN NEW;
END; $funcemp$ LANGUAGE plpgsql;

CREATE TRIGGER stationStatusControl BEFORE INSERT OR UPDATE ON measurement FOR EACH ROW EXECUTE PROCEDURE stationStatusControl();

/*
=================================================================================================
::::::::::::::::::::::::::::::::::::::::::::: PLAN :::::::::::::::::::::::::::::::::::::::::::::
=================================================================================================
*/

/*
=================================================================================================
trigger: capitalizePlan()
whatdoes: capitaliza el atributo description de la relacion plan.
=================================================================================================
*/

CREATE OR REPLACE FUNCTION capitalizePlan() RETURNS TRIGGER AS $funcemp$
BEGIN
	new.description := trim(initcap(new.description));
	new.historical_data := trim(initcap(new.historical_data));
	RETURN NEW;
END; $funcemp$ LANGUAGE plpgsql;

CREATE TRIGGER capitalizePlan BEFORE INSERT OR UPDATE ON plan FOR EACH ROW EXECUTE PROCEDURE capitalizePlan();

/*
=================================================================================================
::::::::::::::::::::::::::::::::::::::::::: FINALUSER :::::::::::::::::::::::::::::::::::::::::::
=================================================================================================
*/

/*
=================================================================================================
trigger: capitalizeFinaluser()
whatdoes: capitaliza los atributos firstname, lastname, email de la relacion finaluser.
=================================================================================================
*/

CREATE OR REPLACE FUNCTION capitalizeFinaluser() RETURNS TRIGGER AS $funcemp$
BEGIN
	new.email := trim(lower(new.email));
	new.username := trim(initcap(new.username));
	RETURN NEW;
END; $funcemp$ LANGUAGE plpgsql;

CREATE TRIGGER capitalizeFinaluser BEFORE INSERT OR UPDATE ON finaluser FOR EACH ROW EXECUTE PROCEDURE capitalizeFinaluser();

/*
=================================================================================================
trigger: deleteUserAfterClient()
whatdoes: luego de eliminar un cliente, elimina los datos de usuario del mismo.
=================================================================================================
*/

CREATE OR REPLACE FUNCTION deleteUserAfterClient() RETURNS TRIGGER AS $funcemp$
BEGIN
	DELETE FROM finaluser WHERE finaluser.id_finaluser=OLD.id_finaluser;
	RETURN NEW;
END; $funcemp$ LANGUAGE plpgsql;

CREATE TRIGGER deleteUserAfterClient AFTER DELETE ON client FOR EACH ROW EXECUTE PROCEDURE deleteUserAfterClient();

/*
=================================================================================================
trigger: deleteUserAfterAdmin()
whatdoes: luego de eliminar un cliente, elimina los datos de usuario del mismo.
=================================================================================================
*/

CREATE OR REPLACE FUNCTION deleteUserAfterAdmin() RETURNS TRIGGER AS $funcemp$
BEGIN
	DELETE FROM finaluser WHERE finaluser.id_finaluser=OLD.id_finaluser;
	RETURN NEW;
END; $funcemp$ LANGUAGE plpgsql;

CREATE TRIGGER deleteUserAfterAdmin AFTER DELETE ON administrator FOR EACH ROW EXECUTE PROCEDURE deleteUserAfterAdmin();

/*
=================================================================================================
::::::::::::::::::::::::::::::::::::::::::::: ADMIN :::::::::::::::::::::::::::::::::::::::::::::
=================================================================================================
*/

/*
=================================================================================================
trigger: signUpAsAdmin()
whatdoes: registra un admin al dar de alta un usuario.
=================================================================================================
*/

CREATE OR REPLACE FUNCTION signUpAsAdmin() RETURNS TRIGGER AS $funcemp$
DECLARE
	currentuser varchar;
BEGIN
	currentuser := (SELECT current_user);
	if (currentuser = 'developper') then
		INSERT INTO administrator(id_finaluser)
			VALUES(NEW.id_finaluser);
	end if;
	RETURN NEW;
END; $funcemp$ LANGUAGE plpgsql;

CREATE TRIGGER signUpAsAdmin AFTER INSERT ON finaluser FOR EACH ROW EXECUTE PROCEDURE signUpAsAdmin();

/*
=================================================================================================
:::::::::::::::::::::::::::::::::::::::::::: CLIENT ::::::::::::::::::::::::::::::::::::::::::::
=================================================================================================
*/

/*
=================================================================================================
trigger: signUpAsClient()
whatdoes: registra un cliente al dar de alta un usuario.
=================================================================================================
*/

CREATE OR REPLACE FUNCTION signUpAsClient() RETURNS TRIGGER AS $funcemp$
DECLARE
	planbasic plan% ROWTYPE;
	currentuser varchar;
BEGIN
	currentuser := (SELECT current_user);
	if (currentuser = 'client') then
		planbasic := (SELECT plan FROM plan WHERE plan.description='Basic');

		INSERT INTO client(available_consults, suscribed_to_plan, id_finaluser)
			VALUES(planbasic.amount_consults, planbasic.description, NEW.id_finaluser);
	end if;
	RETURN NEW;
END; $funcemp$ LANGUAGE plpgsql;

CREATE TRIGGER signUpAsClient AFTER INSERT ON finaluser FOR EACH ROW EXECUTE PROCEDURE signUpAsClient();

/*
=================================================================================================
trigger: availableConsultsControl()
whatdoes: controla las consultas disponibles del cliente.
=================================================================================================
*/

CREATE OR REPLACE FUNCTION availableConsultsControl() RETURNS TRIGGER AS $funcemp$
DECLARE
	amountcurrentplanqueries plan.amount_consults%TYPE;
	amountqueriesmade queryhistory.amount_consults%TYPE;
	availableconsults client.available_consults%TYPE;
BEGIN
	amountcurrentplanqueries := (SELECT plan.amount_consults FROM plan, client 
								 	WHERE client.id_client=new.id_client AND client.suscribed_to_plan=plan.description);
	-- raise notice 'amountcurrentplanqueries: %', amountcurrentplanqueries;
	amountqueriesmade := new.amount_consults;
	-- raise notice 'amountqueriesmade: %', amountqueriesmade;
	
	availableconsults := (SELECT client.available_consults FROM client WHERE client.id_client=new.id_client);
	-- raise notice 'availableconsults: %', availableconsults;
	
	if (availableconsults = 0) then
		raise exception 'Ha llegado a su limite de consultas.';
	else
		UPDATE client SET available_consults = amountcurrentplanqueries-amountqueriesmade
			WHERE client.id_client=new.id_client;
	end if;
	RETURN NEW;
END; $funcemp$ LANGUAGE plpgsql;

CREATE TRIGGER availableConsultsControl AFTER UPDATE ON queryhistory FOR EACH ROW EXECUTE PROCEDURE availableConsultsControl();

/*
=================================================================================================
:::::::::::::::::::::::::::::::::::::::::::: APIKEY ::::::::::::::::::::::::::::::::::::::::::::
=================================================================================================
*/

/*
=================================================================================================
trigger: capitalizeApikey()
whatdoes: capitaliza el atributo name_apikey de la relacion apikey.
=================================================================================================
*/

CREATE OR REPLACE FUNCTION capitalizeApikey() RETURNS TRIGGER AS $funcemp$
BEGIN
	new.name_apikey := trim(initcap(new.name_apikey));
	RETURN NEW;
END; $funcemp$ LANGUAGE plpgsql;

CREATE TRIGGER capitalizeApikey BEFORE INSERT OR UPDATE ON apikey FOR EACH ROW EXECUTE PROCEDURE capitalizeApikey();

/*
=================================================================================================
trigger: generateDefaultApikey()
whatdoes: genera un apikey por defecto al dar de alta un cliente y se asocia al mismo.
=================================================================================================
*/

CREATE OR REPLACE FUNCTION generateDefaultApikey() RETURNS TRIGGER AS $funcemp$
DECLARE
BEGIN	
	INSERT INTO apikey(id_client) VALUES(NEW.id_client);
	RETURN NEW;
END; $funcemp$ LANGUAGE plpgsql;

CREATE TRIGGER generateDefaultApikey AFTER INSERT ON client FOR EACH ROW EXECUTE PROCEDURE generateDefaultApikey();

/*
=================================================================================================
::::::::::::::::::::::::::::::::::::::::: QUERYHISTORY :::::::::::::::::::::::::::::::::::::::::
=================================================================================================
*/

/*
=================================================================================================
trigger: generateQueryhistory()
whatdoes: genera un registro en queryhistory por defecto y se le asocia un cliente.
=================================================================================================
*/

CREATE OR REPLACE FUNCTION generateQueryHistory() RETURNS TRIGGER AS $funcemp$
DECLARE
BEGIN	
	INSERT INTO queryhistory(id_client) VALUES(NEW.id_client);
	RETURN NEW;
END; $funcemp$ LANGUAGE plpgsql;

CREATE TRIGGER generateQueryhistory AFTER INSERT ON client FOR EACH ROW EXECUTE PROCEDURE generateQueryhistory();


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


/*
===========================================================================================================================================
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: INSERTS :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
===========================================================================================================================================
*/


/*
=================================================================================================
::::::::::::::::::::::::::::::::::::::: STATION/LOCATION :::::::::::::::::::::::::::::::::::::::
=================================================================================================
*/

SELECT registerStation('BASE LARROQUE', -33.0333, -59.0167, 'ARGENTINA', 'ENTRE RIOS', 'LARROQUE', '2854');
SELECT registerStation('BASE CONCEPCION DEL URUGUAY', -32.4833, -58.2283, 'ARGENTINA', 'ENTRE RIOS', 'CONCEPCION DEL URUGUAY', '3260');
SELECT registerStation('BASE GUALEGUAYCHU', -33.0103, -58.6436, 'ARGENTINA', 'ENTRE RIOS', 'GUALEGUAYCHU', '2820');
SELECT registerStation('BASE CONCORDIA', -31.4, -58.0333, 'ARGENTINA', 'ENTRE RIOS', 'CONCORDIA', '3200');
SELECT registerStation('BASE CORRIENTES', -27.4667, -58.8333, 'ARGENTINA', 'CORRIENTES', 'CORRIENTES', '3400');
SELECT registerStation('BASE BARRIO ALTO PALERMO', -31.3667, -64.2167, 'ARGENTINA', 'BUENOS AIRES', 'BARRIO ALTO PALERMO', '5009');
SELECT registerStation('BASE VILLAGUAY', -58.4666, -31.3500, 'ARGENTINA', 'ENTRE RIOS', 'VILLAGUAY', '3240');
SELECT registerStation('BASE BASAVILBASO', -32.3667, -58.8833, 'ARGENTINA', 'ENTRE RIOS', 'BASAVILBASO', '3170');
SELECT registerStation('BASE SANTA FE', -31.6333, -60.7, 'ARGENTINA', 'ENTRE RIOS', 'SANTA FE', '3000');
SELECT registerStation('BASE PARANA', -31.7333, -60.5333, 'ARGENTINA', 'ENTRE RIOS', 'PARANA', '3100');

/*
=================================================================================================
::::::::::::::::::::::::::::::::::::::::::::: PLAN :::::::::::::::::::::::::::::::::::::::::::::
=================================================================================================
*/

INSERT INTO plan(description, price, amount_consults, historical_data) VALUES('BASIC', 0, 50, 'No');
INSERT INTO plan(description, price, amount_consults, historical_data) VALUES('INTERMEDIATE', 5.00, 300, 'Daily');
INSERT INTO plan(description, price, amount_consults, historical_data) VALUES('PREMIUM', 15.00, 2147483647, 'Weekly');

/*
=================================================================================================
::::::::::::::::::::::::::::::::::::::::::::: ADMIN :::::::::::::::::::::::::::::::::::::::::::::
=================================================================================================
*/

SET SESSION ROLE developper; -- Dando de alta un administrador con el ROL Developper

INSERT INTO finaluser (id_finaluser, email, username, birthdate) VALUES(generateRandomId(15), 'leandrojaviercepeda1@gmail.com', 'LEANDRO CEPEDA', '09/09/1992');

COMMIT;