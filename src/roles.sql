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