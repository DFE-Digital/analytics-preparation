create table if not exists locations_to_ignore (
	id serial primary key,
	value varchar(64) not null
);


insert into locations_to_ignore(value) values ('ST1 6BD');

create unique index if not exists locations_to_ignore_values on locations_to_ignore(value);
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
create or replace view candidates_acceptance_record as (

	-- check the outcome of candidate placement requests
	-- keyed on gitis_uuid

	select
		bc.gitis_uuid,
		bpr.subject_first_choice,
		bpr.bookings_school_id,

		case
			when bb.id is not null then 'Yes'
			else 'No'
		end as accepted
	
	from
		bookings_candidates bc

	inner join
		bookings_placement_requests bpr
			on bc.id = bpr.candidate_id

	left outer join
		bookings_bookings bb
			on bpr.id = bb.bookings_placement_request_id

	group by
		bc.gitis_uuid,
		bpr.subject_first_choice,
		bpr.bookings_school_id,
		accepted

	order by
		bc.gitis_uuid

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
		r.name AS region,
		bookings_school_searches.analytics_tracking_uuid
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
	WHERE
		upper(location) not in (select value from locations_to_ignore)
);
create or replace view nightly_school_sync as (
	select
		se.date,
		-- the nightly import begins at 04:30
		se.latest_created_at - (date_trunc('day', se.latest_created_at) + '4.5 hours') as duration,
		se.count as number
	from (
		select
			created_at::date as date,
			max(created_at) latest_created_at,
			count(*)
		from
			events
		where
			event_type = 'school_edubase_data_refreshed'
		group by
			date
		order by
			date asc
	) se --summarised events
);
create or replace view placement_request_statuses as (
	select
		bpr.id as placement_request_id,
		bpr.created_at as placement_requested_at,

		coalesce (bprc.created_at, bb.created_at) as decision_made_at,

		case

			/* Placement Requests */

			-- decision to be made: pr has been looked at but hasn't yet been accepted or cancelled
			when (
					bb.id is null
				and bprc.id is null
				and bpr.viewed_at is not null
			)
				then 'decision to be made'

			-- unviewed: pr hasn't yet been looked at by a staff member
			when (
					bb.id is null
				and bprc.id is null
				and bpr.viewed_at is null
			)
				then 'unviewed'

			-- rejection: pr hasn't been accepted but has been cancelled the school
			when (
					bb.id is null
				and bprc.id is not null
				and bprc.cancelled_by = 'school'
			)
				then 'rejected'

			-- withdrawal: pr hasn't been accepted but has been cancelled the candidate
			when (
					bb.id is null
				and bprc.id is not null
				and bprc.cancelled_by = 'candidate'
			)
				then 'withdrawn'

			/* Bookings */

			-- school cancellation: pr has been booked but then cancelled by the school
			when (
					bb.id is not null
				and bprc.id is not null
				and bprc.cancelled_by = 'school'
			)

				then 'school cancelled'

			-- candidate cancelled: pr has been booked but then cancelled by the candidate
			when (
					bb.id is not null
				and bprc.id is not null
				and bprc.cancelled_by = 'candidate'
			)
				then 'candidate cancelled'

			-- booking: it's going ahead!
			when (
					bb.id is not null
				and bprc.id is null
			)
				then 'booking'

			else 'error'

		end status

	from
		bookings_placement_requests bpr

	left outer join
		bookings_bookings bb
			on bpr.id = bb.bookings_placement_request_id

	left outer join
		bookings_placement_request_cancellations bprc
			on bpr.id = bprc.bookings_placement_request_id

	where
		/*
		 * the date school dashboards were released, so we don't
		 * include older placement requests that'll skew results
		 */
		bpr.created_at > '2019-09-04'

);
create or replace view school_onboarded_requests as (
    select
        bs.id                          as "school_id",
        bs.urn                         as "urn",
        bs.name                        as "school_name",
        bpr.id                         as "placement_request_id",
        bp.created_at                  as "onboarded_at",
        bpr.created_at > bp.created_at as "requested_after_onboarding",
        bpr.created_at                 as "placement_requested_at"
    from
        bookings_schools bs
    left outer join
        bookings_profiles bp
            on bs.id = bp.school_id
    /*  note we originally used the ID to join
     *  but it wasn't there from the start, so some
     *  records will be missing it until the fixup script
     *  is run
     */
    inner join
        bookings_placement_requests bpr
        on bs.urn = bpr.urn
        -- on bs.id = bpr.bookings_school_id
    );
create or replace view school_onboarded_status as (
    select
        bs.id                          as "school_id",
        bs.urn                         as "urn",
        bs.name                        as "school_name",
        bp.created_at                  as "onboarded_at",
        max(bpr.created_at)            as "latest_placement_requested_at"
    from
        bookings_schools bs
    left outer join
        bookings_profiles bp
            on bs.id = bp.school_id
    inner join
        bookings_placement_requests bpr
			on bs.urn = bpr.urn
    group by
        bs.id,
        bs.urn,
        bs.name,
        bp.created_at
);
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
create or replace view schools_by_phase as (
	select
		bs.urn,
		bs.name as school_name,
		bp.name as phase_name
	from
		bookings_schools bs
	inner join
		bookings_schools_phases bsp
			on bs.id = bsp.bookings_school_id
	inner join
		bookings_phases bp
			on bsp.bookings_phase_id = bp.id
	order by
		bs.name,
		bp.name
);
