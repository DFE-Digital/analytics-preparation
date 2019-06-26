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
