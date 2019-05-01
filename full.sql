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
CREATE OR REPLACE VIEW bookings_schools_cleansed AS (
	SELECT
		bookings_schools.id,
		bookings_schools.name,
		st_x(bookings_schools.coordinates::geometry) AS st_x,
		st_y(bookings_schools.coordinates::geometry) AS st_y,
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
		bookings_schools.enabled
	FROM
		bookings_schools
);
