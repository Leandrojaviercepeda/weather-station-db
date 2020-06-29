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

/**
DROP TABLE location CASCADE;
DROP TABLE station CASCADE;
DROP TABLE measurement CASCADE;
DROP TABLE administrator CASCADE;
DROP TABLE apikey CASCADE;
DROP TABLE client CASCADE;
DROP TABLE plan CASCADE;
DROP TABLE queryhistory CASCADE;
DROP TABLE finaluser CASCADE;
DROP EXTENSION pgcrypto;
DROP FUNCTION generateRandomId(lenght integer);
*/
