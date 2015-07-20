-- after running py-mysql2pgsql to create database,
-- add PostGIS extension and spatial columns for co-ordinates
CREATE EXTENSION postgis;
CREATE EXTENSION postgis_topology;

CREATE TABLE coord_geog (id serial primary key, trip_id serial, recorded timestamp, geog geography(POINT,4326));

INSERT INTO coord_geog (trip_id, recorded, geog) (SELECT trip_id, recorded, ST_SetSRID(ST_MakePoint(longitude, latitude), 4326) from coord);

SELECT AddGeometryColumn('coord_geog', 'geom', 4326, 'POINT', 2);

update coord_geog set geom=geog::geometry;

-- table to hold trip geometries, to be populated by trim_trips.py script
CREATE TABLE trip_geom AS SELECT id, purpose, start, stop from trip;
SELECT AddGeometryColumn('trip_geom', 'geom', 4326, 'LINESTRING', 2);

-----------------------------------------------------------
-- TODO: update wm column?
--SELECT AddGeometryColumn('trip_geom', 'the_geom_webmercator', 3857, 'LINESTRING', 2);
-- update trip_geom set the_geom_webmercator = ST_Transform(geom, 3857);

CREATE TABLE coord_geom (id serial primary key, trip_id serial, recorded timestamp, purpose varchar(25));
SELECT AddGeometryColumn('coord_geom', 'geom', 4326, 'POINT', 2);
SELECT AddGeometryColumn('coord_geom', 'the_geom_webmercator', 3857, 'POINT', 2);

INSERT INTO coord_geom (trip_id, recorded, geom, the_geom_webmercator) (SELECT trip_id, recorded, 
    ST_SetSRID(ST_MakePoint(longitude, latitude), 4326), ST_SetSRID(ST_MakePoint(longitude, latitude), 3857) from coord);

update coord_geom set the_geom_webmercator = CDB_TransformToWebmercator(geom);

alter table coord_geom add column purpose varchar(25);
create index coord_geom_trip_id_idx on coord_geom(trip_id);
vacuum coord_geom;
vacuum analyze coord_geom;
update coord_geom set purpose = trip.purpose from trip where trip.id = coord_geom.trip_id;

------------------------------------

-- indexing
CREATE INDEX coord_geog_geog ON coord_geog USING GIST (geog);
CREATE INDEX coord_geog_recorded ON coord_geog(recorded);
CREATE INDEX coord_geog_trip_id ON coord_geog(trip_id);

VACUUM;
VACUUM ANALYZE;

