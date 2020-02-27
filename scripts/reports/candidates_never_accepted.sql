create or replace view candidates_never_accepted as (
	select
		gitis_uuid
	from
		candidates_acceptance_record
	where
		gitis_uuid not in (
			/*
				get a list of every candidate who has ever been accepted; every
				remaining uuid that's not in this list must never have been
				accepted
			*/
			select
				gitis_uuid
			from
				candidates_acceptance_record
			where
				accepted = 'Yes'
			group by
				gitis_uuid
		)
	group by
		gitis_uuid
);
