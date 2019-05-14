DROP MATERIALIZED VIEW IF EXISTS bookings_school_searches_cleansed;

CREATE MATERIALIZED VIEW bookings_school_searches_cleansed AS (
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
