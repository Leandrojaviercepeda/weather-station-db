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

INSERT INTO finaluser (id_finaluser, email, username, birthdate) VALUES(generateRandomId(15), 'leandrojaviercepeda1@gmail.com', 'LEANDRO CEPEDA', '21/02/1979');
