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

-- indexing
CREATE INDEX coord_geog_geog ON coord_geog USING GIST (geog);
CREATE INDEX coord_geog_recorded ON coord_geog(recorded);
CREATE INDEX coord_geog_trip_id ON coord_geog(trip_id);

VACUUM;
VACUUM ANALYZE;

