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
