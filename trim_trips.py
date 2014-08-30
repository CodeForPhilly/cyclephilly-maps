#!/usr/bin/env python

"""
To anonymize trip linestrings for display, remove points from beginning and end
where points are within a given distance of the start or end points.
"""

import psycopg2

REMOVE_DIST = 200 # remove points within this distance in meters of origin/destination

"""Helper function to delete trip with no accepted co-ordinates"""
def delete_trip(trip_id):
    c.execute('delete from trip_geom where id=%s;', (trip_id,))
    conn.commit()

"""Helper function to append ids of co-ordinates within REMOVE_DIST
   parameters:
   coords -> ordered list of co-ordinate rows for trip, starting at point to check from
   returns:
   list of ids for co-ordinates to skip
"""
def find_near(coords):
    skip_ids = []
    for coord in coords:
        c.execute('select ST_DWithin(a.geog, b.geog, %s) from coord_geog a, coord_geog b where a.id=%s and b.id=%s;', (REMOVE_DIST, start_coord_id, coord[0]))
        is_near = c.fetchone()[0]
        if is_near:
            trim_start_ct += 1
            skip_ids.append(coord[0])
        else:
            break
    return skip_ids


conn = psycopg2.connect('dbname=cyclephilly')
c = conn.cursor()

c.execute('select id from trip_geom;')
trips = c.fetchall()

print("Have %d trips!" % len(trips))

for trip in trips:
    trip_id = trip[0]
    c.execute('select id from coord_geog where trip_id=%s order by recorded asc;', (trip_id,))
    coords = c.fetchall()
    coords_ct = len(coords)
    if coords_ct == 0:
        print('Trip #%d has no coordinates' % trip_id)
        delete_trip(trip_id)
        continue
        
    start_coord_id = coords[0][0]
    end_coord_id = coords[coords_ct-1][0]
    
    # trim from start
    trim_start_ct = 0
    skip_ids = find_near(coords)
    
    if trim_start_ct == coords_ct:
        print('All %d coordinates in trip #%d are within %d m of the start point.' % (coords_ct, trip_id, REMOVE_DIST))
        delete_trip(trip_id)
        continue
    else:
        print('Trimming %d coordinates from start of trip #%d' % (trim_start_ct, trip_id))
                
    # trim from end
    trim_end_ct = 0
    coords.reverse()
    skip_ids.extend(find_near(coords))
            
    if trim_end_ct == coords_ct:
        print('All %d coordinates in trip #%d are within %d m of the end point.' % (coords_ct, trip_id, REMOVE_DIST))
        delete_trip(trip_id)
        continue
    elif (trim_start_ct + trim_end_ct) >= coords_ct:
        print('All coordinates in trip #%d are within %d m of the either the start or the end point.' % (trip_id, REMOVE_DIST))
        delete_trip(trip_id)
        continue
    
    print('Trimming %d coordinates from end of trip #%d' % (trim_end_ct, trip_id))
    
    c.execute('UPDATE trip_geom t SET geom=(SELECT ST_MakeLine(line.geom) FROM (SELECT c.recorded, c.geom FROM coord_geog c WHERE c.trip_id=t.id AND c.id NOT IN %s ORDER BY c.recorded ASC) as line) WHERE t.id=%s;', (tuple(skip_ids), trip_id))
    conn.commit()
    
conn.close()
