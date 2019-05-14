DROP MATERIALIZED VIEW IF EXISTS districts;

CREATE MATERIALIZED VIEW districts AS (
	SELECT
		lad.lad13nm AS name,
		st_geomfromewkb(lad.wkb_geometry) AS edge
	FROM
		local_authority_districts AS lad
);

CREATE INDEX idx_districts_edges ON districts USING gist (edge) ;
DROP MATERIALIZED VIEW IF EXISTS regions;

CREATE MATERIALIZED VIEW regions AS (
	SELECT
		er.eer13nm AS name,
		st_geomfromewkb(er.wkb_geometry) AS edge
	FROM
		electoral_regions AS er
);

CREATE INDEX idx_regions_edges ON regions USING gist (edge) ;
CREATE OR REPLACE VIEW bookings_school_searches_cleansed AS (
	SELECT
		bookings_school_searches.id,
		bookings_school_searches.location,
		bookings_school_searches.radius,
		bookings_school_searches.max_fee,
		bookings_school_searches.page,
		bookings_school_searches.number_of_results,
		st_x(bookings_school_searches.coordinates::geometry) AS x,
		st_y(bookings_school_searches.coordinates::geometry) AS y,
		bookings_school_searches.created_at,
		subject_id,
		phase_id,
		d.name AS district,
		r.name AS region
	FROM
		bookings_school_searches
	LEFT JOIN LATERAL
		unnest(bookings_school_searches.subjects) subject_id
		ON true
	LEFT JOIN LATERAL
		unnest(bookings_school_searches.phases) phase_id
		ON true
	LEFT OUTER JOIN
		regions AS r
			ON st_contains(
				r.edge,
				bookings_school_searches.coordinates::geometry
			)
	LEFT OUTER JOIN
		districts AS d
			ON st_contains(
				d.edge,
				bookings_school_searches.coordinates::geometry
			)
);
CREATE OR REPLACE VIEW bookings_schools_cleansed AS (
	SELECT
		bookings_schools.id,
		bookings_schools.name,
		st_x(bookings_schools.coordinates::geometry) AS x,
		st_y(bookings_schools.coordinates::geometry) AS y,
		bookings_schools.created_at,
		bookings_schools.updated_at,
		bookings_schools.urn,
		bookings_schools.website,
		bookings_schools.address_1,
		bookings_schools.address_2,
		bookings_schools.address_3,
		bookings_schools.town,
		bookings_schools.county,
		bookings_schools.postcode,
		bookings_schools.bookings_school_type_id,
		bookings_schools.contact_email,
		bookings_schools.placement_info,
		bookings_schools.teacher_training_provider,
		bookings_schools.teacher_training_info,
		bookings_schools.primary_key_stage_info,
		bookings_schools.availability_info,
		bookings_schools.teacher_training_website,
		bookings_schools.enabled,
		d.name AS district,
		r.name AS region
	FROM
		bookings_schools
	LEFT OUTER JOIN
		regions AS r
			ON st_contains(
				r.edge,
				bookings_schools.coordinates::geometry
			)
	LEFT OUTER JOIN
		districts AS d
			ON st_contains(
				d.edge,
				bookings_schools.coordinates::geometry
			)
);
