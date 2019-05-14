DROP MATERIALIZED VIEW IF EXISTS regions;

CREATE MATERIALIZED VIEW regions AS (
	SELECT
		er.eer13nm AS name,
		st_geomfromewkb(er.wkb_geometry) AS edge
	FROM
		electoral_regions AS er
);

CREATE INDEX idx_regions_edges ON regions USING gist (edge) ;
