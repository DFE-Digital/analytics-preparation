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
		r.name AS region,
		bookings_schools.views,
		bookings_schools.availability_preference_fixed,
		case
			when bookings_schools.created_at < '2019-04-01' then true
			else false
		end as sep
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
	LEFT OUTER JOIN
		bookings_profiles
			ON bookings_schools.id = bookings_profiles.school_id
	WHERE
		(
			bookings_profiles.id is not null

			OR

			-- this is an easy way to identify schools that were
			-- part of the initial imports
			bookings_schools.contact_email is not null
		)
);
