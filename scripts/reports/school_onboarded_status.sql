create or replace view school_onboarded_requests as (
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
    group by (
        bs.id,
        bs.urn,
        bs.name,
        bp.created_at
    )
;
