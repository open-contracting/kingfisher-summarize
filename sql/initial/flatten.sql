-- https://www.postgresql.org/docs/current/queries-with.html
CREATE OR REPLACE FUNCTION flatten (jsonb)
    RETURNS TABLE (
        path text,
        object_property integer,
        array_item integer)
    LANGUAGE 'sql'
    PARALLEL SAFE
    AS $$
    WITH RECURSIVE t (
        key,
        value,
        object_property,
        array_item
    ) AS (
        SELECT
            j.key,
            j.value,
            1,
            0
        FROM
            jsonb_each($1) AS j
        UNION ALL (
            WITH prev AS (
                SELECT
                    *
                FROM
                    t -- recursive reference to query "t" must not appear more than once
            )

            SELECT
                prev.key || '/' || next.key,
                next.value,
                1,
                0
            FROM
                prev,
                jsonb_each(prev.value) next
            WHERE
                jsonb_typeof(prev.value) = 'object'

            UNION ALL

            SELECT
                prev.key,
                next.value,
                0,
                1
            FROM
                prev,
                jsonb_array_elements(prev.value) next
            WHERE
                jsonb_typeof(prev.value) = 'array'
                AND jsonb_typeof(prev.value -> 0) = 'object'
        )
    )
    SELECT
        key AS path,
        object_property,
        array_item
    FROM
        t;

$$;

-- This function is not used by this project, but it is defined as a helper for analysts.
CREATE OR REPLACE FUNCTION flatten_with_values (jsonb)
    RETURNS TABLE (
        path text,
        object_property integer,
        array_item integer,
        value jsonb)
    LANGUAGE 'sql'
    PARALLEL SAFE
    AS $$
    WITH RECURSIVE t (
        key,
        value,
        object_property,
        array_item
    ) AS (
        SELECT
            j.key,
            j.value,
            1,
            0
        FROM
            jsonb_each($1) AS j
        UNION ALL (
            WITH prev AS (
                SELECT
                    *
                FROM
                    t -- recursive reference to query "t" must not appear more than once
            )

            SELECT
                prev.key || '/' || next.key,
                next.value,
                1,
                0
            FROM
                prev,
                jsonb_each(prev.value) next
            WHERE
                jsonb_typeof(prev.value) = 'object'

            UNION ALL

            SELECT
                prev.key,
                next.value,
                0,
                1
            FROM
                prev,
                jsonb_array_elements(prev.value) next
            WHERE
                jsonb_typeof(prev.value) = 'array'
                AND jsonb_typeof(prev.value -> 0) = 'object'
        )
    )
    SELECT
        key AS path,
        object_property,
        array_item,
        value
    FROM
        t;

$$;

