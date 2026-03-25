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
    SELECT CASE
        WHEN 'camper_stop'::public.canonical_place_type_enum IN (p_primary, p_secondary, p_tertiary, p_quaternary)
            THEN 'camper_stop'::public.canonical_place_type_enum
        ELSE COALESCE(
            NULLIF(p_primary, 'poi'::public.canonical_place_type_enum),
            NULLIF(p_secondary, 'poi'::public.canonical_place_type_enum),
            NULLIF(p_tertiary, 'poi'::public.canonical_place_type_enum),
            NULLIF(p_quaternary, 'poi'::public.canonical_place_type_enum),
            p_primary,
            p_secondary,
            p_tertiary,
            p_quaternary
        )
    END
$$;

COMMENT ON FUNCTION public.resolve_canonical_place_type(public.canonical_place_type_enum, public.canonical_place_type_enum, public.canonical_place_type_enum, public.canonical_place_type_enum) IS
'Resolves canonical place type across prioritized sources while preferring specific values over fallback poi and elevating camper_stop above campsite when present in any source.';
