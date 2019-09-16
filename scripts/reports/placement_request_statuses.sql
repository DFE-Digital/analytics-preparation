create or replace view placement_request_statuses as (
	select
		bpr.id as placement_request_id,
		bpr.created_at as placement_requested_at,

		coalesce (bprc.created_at, bb.created_at) as decision_made_at,

		case
			-- rejection: pr hasn't been accepted but has been cancelled
			when (bb.id is null and bprc.id is not null) then 'rejected'

			-- cancellation: pr has been booked but then cancelled by the school
			when (
					bb.id is not null
				and bprc.id is not null
				and bprc.cancelled_by = 'school'
			)

				then 'cancelled'

			-- withdrawal: pr has been booked but then cancelled by the candidate
			when (
					bb.id is not null
				and bprc.id is not null
				and bprc.cancelled_by = 'candidate'
			)
				then 'withdrawn'

			-- decision to be made: pr hasn't yet been accepted or cancelled
			when (
					bb.id is null
				and bprc.id is null
			)
				then 'decision to be made'

			-- otherwise, accepted
			else 'accepted'

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
