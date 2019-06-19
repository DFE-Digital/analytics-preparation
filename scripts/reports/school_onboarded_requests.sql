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
