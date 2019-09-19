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
