-- Migration: Create get_nearby_places RPC function
-- Purpose: Provide nearby public places for the product detail page
-- Important: parameter names must match the product RPC call exactly

create or replace function public.get_nearby_places(
  lat_param double precision,
  lng_param double precision,
  radius_km double precision default 5,
  limit_param integer default 6
)
returns table (
  place_id bigint,
  name text,
  lat double precision,
  lng double precision,
  place_types text[],
  estimated_price numeric,
  google_rating numeric,
  distance_km double precision,
  has_restrooms boolean,
  has_shower boolean,
  has_electricity boolean,
  has_wifi boolean,
  pets_allowed boolean
)
language sql
stable
security definer
set search_path = public
as $$
  with ref as (
    select st_setsrid(st_makepoint(lng_param, lat_param), 4326)::geography as ref_geog
  )
  select
    prp.id as place_id,
    prp.name,
    prp.lat,
    prp.lon as lng,
    array_remove(
      array[
        nullif(trim(prp.place_type), ''),
        nullif(trim(prp.source_place_type), '')
      ],
      null
    ) as place_types,
    null::numeric as estimated_price,
    null::numeric as google_rating,
    st_distance(
      coalesce(
        p.geom,
        st_setsrid(st_makepoint(prp.lon, prp.lat), 4326)
      )::geography,
      ref.ref_geog
    ) / 1000.0 as distance_km,
    prp.has_restrooms,
    prp.has_shower,
    prp.has_electricity,
    prp.has_wifi,
    prp.pets_allowed
  from public.places p
  join public.place_resolved_public prp
    on prp.id = p.id
  cross join ref
  where p.is_active = true
    and prp.name is not null
    and prp.lat is not null
    and prp.lon is not null
    and st_dwithin(
      coalesce(
        p.geom,
        st_setsrid(st_makepoint(prp.lon, prp.lat), 4326)
      )::geography,
      ref.ref_geog,
      greatest(radius_km, 0) * 1000.0
    )
  order by distance_km asc, prp.id asc
  limit greatest(limit_param, 1);
$$;

grant execute on function public.get_nearby_places(
  double precision,
  double precision,
  double precision,
  integer
) to anon, authenticated, service_role;

comment on function public.get_nearby_places(
  double precision,
  double precision,
  double precision,
  integer
) is
'Returns nearby public places around the provided lat/lng using places.geom for geo filtering and place_resolved_public for display fields.';

notify pgrst, 'reload schema';
