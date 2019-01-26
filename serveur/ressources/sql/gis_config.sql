-- User creation
CREATE ROLE gis WITH LOGIN ENCRYPTED PASSWORD 'gis';
-- Database creation
\c postgres
DROP DATABASE IF EXISTS gis;
CREATE DATABASE gis;
-- Changing ownership
ALTER DATABASE gis OWNER TO gis;

\connect gis;
-- Enable PostGIS (includes raster)
CREATE EXTENSION postgis;

-- ----------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------
-- Import GIS with following shell commands:
-- -----------------------------------------
-- shp2pgsql -d -s 4326 -g geom -I ./regions-20180101.shp regions | psql -U gis -h localhost
-- shp2pgsql -d -s 4326 -g geom -I ./departements-20180101.shp departements | psql -U gis -h localhost
-- shp2pgsql -d -s 4326 -g geom -I ./communes-20181110.shp communes | psql -U gis -h localhost
-- ----------------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------
-- Add needed columns to tables
ALTER TABLE regions ADD COLUMN lon NUMERIC;
ALTER TABLE regions ADD COLUMN lat NUMERIC;
ALTER TABLE regions ADD COLUMN svg TEXT;
ALTER TABLE regions ADD COLUMN cpt int;

ALTER TABLE departements ADD COLUMN rgid INTEGER;
ALTER TABLE departements ADD COLUMN lon NUMERIC;
ALTER TABLE departements ADD COLUMN lat NUMERIC;
ALTER TABLE departements ADD COLUMN svg TEXT;
ALTER TABLE departements ADD COLUMN cpt int;
ALTER TABLE departements ADD CONSTRAINT FK_rgid FOREIGN KEY (rgid) REFERENCES regions (gid) ON DELETE CASCADE;

ALTER TABLE communes ADD COLUMN dgid INTEGER;
ALTER TABLE communes ADD COLUMN rgid INTEGER;
ALTER TABLE communes ADD COLUMN lon NUMERIC;
ALTER TABLE communes ADD COLUMN lat NUMERIC;
ALTER TABLE communes ADD COLUMN svg TEXT;
ALTER TABLE communes ADD COLUMN cpt int;
ALTER TABLE communes ADD CONSTRAINT FK_dgid FOREIGN KEY (dgid) REFERENCES departements (gid) ON DELETE CASCADE;
ALTER TABLE communes ADD CONSTRAINT FK_rgid FOREIGN KEY (rgid) REFERENCES regions (gid) ON DELETE CASCADE;

UPDATE regions SET cpt = 0 WHERE True;
UPDATE departements SET cpt = 0 WHERE True;
UPDATE communes SET cpt = 0 WHERE True;

-- Remove unecessary columns
alter table regions drop column wikipedia;
alter table regions drop column nuts2;
alter table regions drop column surf_km2;

alter table departements drop column wikipedia;
alter table departements drop column nuts3;
alter table departements drop column surf_km2;

alter table communes drop column wikipedia;
alter table communes drop column surf_ha;

-- Update regions svg column (from Geometry)
UPDATE regions
  SET svg = TempAlias.svg
  FROM
      (SELECT ST_AsSVG(geom, 1, 5) AS svg,
              regions.gid AS rgid
         FROM regions) TempAlias
  WHERE gid = TempAlias.rgid;

-- Update departements svg column (from Geometry)
UPDATE departements
  SET svg = TempAlias.svg
  FROM
      (SELECT ST_AsSVG(geom, 1, 5) AS svg,
              departements.gid AS dgid
         FROM departements) TempAlias
  WHERE gid = TempAlias.dgid;
  
-- Update communes svg column (from Geometry)
UPDATE communes
  SET svg = TempAlias.svg
  FROM
      (SELECT ST_AsSVG(geom, 1, 5) AS svg,
              communes.gid AS cgid
         FROM communes) TempAlias
  WHERE gid = TempAlias.cgid;


-- Update departements rgid column (from Geometry)
UPDATE departements
  SET rgid = tempAlias.rgid
  FROM
      (SELECT regions.gid AS rgid,
              departements.gid AS dgid
         FROM regions, departements
         WHERE st_contains(regions.geom, departements.geom)) TempAlias
  WHERE gid = TempAlias.dgid;

-- Update  departements rgid column (Corse)
  UPDATE departements SET rgid=2 where gid = 12 or gid = 13;

-- Update communes rgid and dgid column (from Geometry)
UPDATE communes
  SET rgid = tempAlias.rgid,
      dgid = tempAlias.dgid
  FROM
      (SELECT departements.rgid AS rgid,
              departements.gid AS dgid,
              communes.gid AS cgid
         FROM departements, communes
         WHERE st_contains(departements.geom, communes.geom)) TempAlias
  WHERE gid = TempAlias.cgid;

-- Update communes rgid and dgid column (Generic)
UPDATE communes
  SET rgid = tempAlias.rgid,
      dgid = tempAlias.dgid
  FROM
      (SELECT departements.rgid AS rgid,
              departements.gid AS dgid,
              communes.gid AS cgid
         FROM departements, communes
         WHERE departements.code_insee = substring(communes.insee, 1, 2)
           and communes.dgid is null) TempAlias
  WHERE gid = TempAlias.cgid;

-- Update communes rgid and dgid column (DOM/TOM)
UPDATE communes
  SET rgid = tempAlias.rgid,
      dgid = tempAlias.dgid
  FROM
      (SELECT departements.rgid AS rgid,
              departements.gid AS dgid,
              communes.gid AS cgid
         FROM departements, communes
         WHERE departements.code_insee = substring(communes.insee, 1, 3)
           and communes.dgid is null
           and substring(communes.insee, 1, 2) = '97') TempAlias
  WHERE gid = TempAlias.cgid;

-- Update departement column (Lyon Metropole)
UPDATE communes
  SET dgid = tempAlias.dgid,
      rgid = tempAlias.rgid
  FROM
      (SELECT departements.rgid AS rgid,
              departements.gid AS dgid,
              communes.gid AS cgid
         FROM departements, communes
         WHERE departements.code_insee = '64'
           and communes.dgid is null
           and substring(communes.insee, 1, 2) = '69') TempAlias
  WHERE gid = TempAlias.cgid;

-- Remove Saint-Pierre & Miquelon-Langlade from communes
delete from communes where gid = 21100 or gid = 21072;

-- Update center column for regions
UPDATE regions
  SET lon = tempAlias.lon,
      lat = tempAlias.lat
  FROM
    (SELECT regions.gid as rgid,
            regions.nom,
            St_x(St_Centroid(regions.geom)) as lon,
            St_y(St_Centroid(regions.geom)) as lat
      FROM regions) TempAlias
  WHERE
    regions.gid = TempAlias.rgid;

-- Update center column for departements
UPDATE departements
  SET lon = tempAlias.lon,
      lat = tempAlias.lat
  FROM
    (SELECT departements.gid as dgid,
            St_x(St_Centroid(departements.geom)) as lon,
            St_y(St_Centroid(departements.geom)) as lat
      FROM departements) TempAlias
  WHERE
    departements.gid = TempAlias.dgid;

-- Update center column for communes
UPDATE communes
  SET lon = tempAlias.lon,
      lat = tempAlias.lat
  FROM
    (SELECT communes.gid as cgid,
            St_x(St_Centroid(communes.geom)) as lon,
            St_y(St_Centroid(communes.geom)) as lat
      FROM communes) TempAlias
  WHERE
    communes.gid = TempAlias.cgid;

-- Test
-- (0 rows)
select gid, nom, insee from communes where dgid is null order by insee;

-- Index creation
CREATE INDEX idx_communes_geom ON communes USING gist(geom);
CREATE INDEX idx_communes_nom ON communes USING btree(nom);
CREATE INDEX idx_departements_geom ON departements USING gist(geom);
CREATE INDEX idx_departements_nom ON departements USING btree(nom);
CREATE INDEX idx_regions_geom ON regions USING gist(geom);
CREATE INDEX idx_regions_nom ON regions USING btree(nom);

-- Application tables
CREATE TABLE protests (
  id serial primary key,
  nom text not NULL,
  description text not NULL,
  start_date timestamp with time zone not NULL,
  expire_date timestamp with time zone not NULL
  );
ALTER TABLE protests OWNER TO gis;

CREATE TABLE protesters (
  id serial primary key,
  uid uuid not NULL UNIQUE,
  lon numeric,
  lat numeric,
  rgid integer REFERENCES regions(gid),
  dgid integer REFERENCES departements(gid),
  cgid integer REFERENCES communes(gid),
  last_seen timestamp with time zone not NULL
  );
ALTER TABLE protesters OWNER TO gis;

CREATE TABLE subscriptions (
  protest_id integer REFERENCES protests(id) ON DELETE CASCADE,
  protester_id integer REFERENCES protesters(id) ON DELETE CASCADE,
  subscription_date timestamp with time zone not NULL,
  PRIMARY KEY (protest_id, protester_id)
);
ALTER TABLE subscriptions OWNER TO gis;

create index on communes (rgid);
create index on communes (dgid);
create index on communes (gid);
create index on departements (rgid);
create index on departements (gid);
create index on regions (gid);
create index on protests (id);
create index on protesters (uid);
create index on protesters (id);
create index on subscriptions (protester_id);


-- Test
--               List of relations
--  Schema |      Name       | Type  |  Owner   
-- --------+-----------------+-------+----------
--  public | communes        | table | gis
--  public | departements    | table | gis
--  public | protesters      | table | gis
--  public | protests        | table | gis
--  public | spatial_ref_sys | table | postgres
--  public | subscriptions   | table | gis
\dt

--                   List of relations
--  Schema |           Name           | Type |  Owner   
-- --------+--------------------------+------+----------
--  public | geography_columns        | view | postgres
--  public | geometry_columns         | view | postgres
--  public | raster_columns           | view | postgres
--  public | raster_overviews         | view | postgres
\dv

-- Aveyron
SELECT nom from departements where st_contains(geom, ST_GeomFromText('POINT(2.56667 44.333328)', 4326));
-- Olemps
SELECT nom from communes where st_contains(geom, ST_GeomFromText('POINT(2.56667 44.333328)', 4326));
