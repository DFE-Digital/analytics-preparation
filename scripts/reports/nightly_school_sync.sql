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
