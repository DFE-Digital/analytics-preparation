DROP MATERIALIZED VIEW IF EXISTS districts;

CREATE MATERIALIZED VIEW districts AS (
	SELECT
		lad.lad13nm AS name,
		st_geomfromewkb(lad.wkb_geometry) AS edge
	FROM
		local_authority_districts AS lad
);

CREATE INDEX idx_districts_edges ON districts USING gist (edge) ;
