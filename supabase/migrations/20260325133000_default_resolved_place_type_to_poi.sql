SET lock_timeout = '10s';
SET statement_timeout = '5min';

CREATE OR REPLACE FUNCTION public.resolve_canonical_place_type(
    p_primary public.canonical_place_type_enum,
    p_secondary public.canonical_place_type_enum DEFAULT NULL,
    p_tertiary public.canonical_place_type_enum DEFAULT NULL,
    p_quaternary public.canonical_place_type_enum DEFAULT NULL
)
RETURNS public.canonical_place_type_enum
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT COALESCE(
        (
            SELECT ranked.place_type
            FROM (
                SELECT t AS place_type
                FROM unnest(ARRAY[p_primary, p_secondary, p_tertiary, p_quaternary]) AS t
                WHERE t IS NOT NULL
                ORDER BY public.canonical_place_type_priority(t) DESC
                LIMIT 1
            ) AS ranked
        ),
        'poi'::public.canonical_place_type_enum
    )
$$;

COMMENT ON FUNCTION public.resolve_canonical_place_type(public.canonical_place_type_enum, public.canonical_place_type_enum, public.canonical_place_type_enum, public.canonical_place_type_enum) IS
'Resolves canonical place type across prioritized sources using explicit product-facing type priority and falls back to poi when all source types are null.';
