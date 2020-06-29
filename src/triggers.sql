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
