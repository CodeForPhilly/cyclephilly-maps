// Windshaft tile server configuration

var Windshaft = require('./lib/windshaft');
var _         = require('underscore');
var config = {
    base_url: '/tiles/:purpose',
    base_url_notable: '/tiles',
    grainstore: {
                 datasource: {
                     user:'$PGUSER',
                     password:'',
                     host: '$PGHOST',
                     port: 5432,
                     geometry_field: 'geom',
                     srid: 4326
                 }
    }, //see grainstore npm for other options
    redis: {host: '127.0.0.1', port: 6379},
    enable_cors: true,
    req2params: function(req, callback) {

        // to enable specify the database column you'd like to interact with
        req.params.interactivity = 'purpose';
        
        req.params.dbname = 'cyclephilly';
        req.params.table = 'trip_geom';
        
        var style = '#trip_geom { ' +
            'line-color: #EFF3FF; ' +
            'line-width: 2; ' +
            '[ purpose = "Commute" ] { line-color: #256baf; } ' +
            '[ purpose = "School" ] { line-color: #dfdeb6; } ' +
            '[ purpose = "Exercise" ] { line-color: #16ac69; } ' +
            '[ purpose = "Social" ] { line-color: #ccd93e; } ' +
            '[ purpose = "Other" ] { line-color: #698ea2; } ' +
            '[ purpose = "other" ] { line-color: #698ea2; } ' +
            '[ purpose = "Work-related" ] { line-color: #0a5983; } ' +
            '[ purpose = "Work-Related" ] { line-color: #0a5983; } ' +
            '[ purpose = "Errand" ] { line-color: #99cccc; } ' +
            '[ purpose = "Shopping" ] { line-color: #2487bc; } ' +
            '} ';

        req.params.sql = "(select * from trip_geom where purpose ilike '" + 
            req.params.purpose + "%') as trip_geom";

        req.params =  _.extend({}, req.params, {style: style});
        
        _.extend(req.params, req.query);

        // send the finished req object on
        callback(null, req);
    }
};

// Initialize tile server on port 4000
var ws = new Windshaft.Server(config);
ws.listen(4000);

console.log("map tiles are now being served out of: http://localhost:4000" + config.base_url + '/:z/:x/:y');
