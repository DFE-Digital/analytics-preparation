CREATE OR REPLACE VIEW schools_by_district_and_onboarded_status AS (
	SELECT
		d.name as district,
		bookings_schools.availability_preference_fixed,
		CASE
			WHEN (
					bookings_profiles.id IS NULL
				OR bookings_schools.contact_email IS NULL
			) THEN
				'no'
			ELSE
				'yes'
		END AS part_of_service,
		bookings_schools.id,
		bookings_schools.name,
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
		bookings_schools.enabled,
		bookings_schools.views

	FROM
		bookings_schools
	LEFT OUTER JOIN
		districts AS d
			ON st_contains(
				d.edge,
				bookings_schools.coordinates::geometry
			)
	LEFT OUTER JOIN
		bookings_profiles
			ON bookings_schools.id = bookings_profiles.school_id
);
