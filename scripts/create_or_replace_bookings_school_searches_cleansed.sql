CREATE OR REPLACE view bookings_school_searches_cleansed (
	SELECT
		bookings_school_searches.id,
		bookings_school_searches.location,
		bookings_school_searches.radius,
		unnest(bookings_school_searches.subjects) AS subject_id,
		unnest(bookings_school_searches.phases) AS phase_id,
		bookings_school_searches.max_fee,
		bookings_school_searches.page,
		bookings_school_searches.number_of_results,
		st_x(bookings_school_searches.coordinates::geometry) AS x,
		st_y(bookings_school_searches.coordinates::geometry) AS y,
		bookings_school_searches.created_at
	FROM
		bookings_school_searches
);
