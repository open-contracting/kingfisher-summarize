CREATE OR REPLACE FUNCTION flatten (jsonb)
    RETURNS TABLE (
        path text,
        object_property integer,
        array_item integer)
    LANGUAGE 'sql'
    PARALLEL SAFE
    AS $$
    -- https://www.postgresql.org/docs/current/queries-with.html
    -- https://github.com/MaayanLab/signature-commons-metadata-api/blob/master/src/migration/1568055725225-jsonb-deep-key-value.ts
    WITH RECURSIVE t (
        KEY,
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
            ),
            obj AS (
                SELECT
                    prev.key || '/' || tt.key,
                    tt.value,
                    1,
                    0
                FROM
                    prev,
                    jsonb_each(prev.value) tt
                WHERE
                    jsonb_typeof(prev.value) = 'object'
            ),
            arr AS (
                SELECT
                    prev.key,
                    tt.value,
                    0,
                    1
                FROM
                    prev,
                    jsonb_array_elements(prev.value) tt
                WHERE
                    jsonb_typeof(prev.value) = 'array'
                    AND jsonb_typeof(prev.value -> 0) = 'object'
            )
            SELECT
                *
            FROM
                obj
            UNION ALL
            SELECT
                *
            FROM
                arr
        )
    )
    SELECT
        KEY AS path,
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
    WITH RECURSIVE all_paths (
        path,
        "value",
        "object_property",
        "array_item"
) AS (
        SELECT
            KEY "path",
            value "value",
            1 "object_property",
            0 "array_item"
        FROM
            jsonb_each($1)
        UNION ALL (
            SELECT
                CASE WHEN key_value IS NOT NULL THEN
                    path || '/'::text || (key_value).KEY::text
                ELSE
                    path
                END "path",
                CASE WHEN key_value IS NOT NULL THEN
                (key_value).value
            ELSE
                array_value
                END "value",
                CASE WHEN key_value IS NOT NULL THEN
                    1
                ELSE
                    0
                END,
                CASE WHEN key_value IS NULL THEN
                    1
                ELSE
                    0
                END
            FROM (
                SELECT
                    path,
                    jsonb_each(
                        CASE WHEN jsonb_typeof(value) = 'object' THEN
                            value
                        ELSE
                            '{}'::jsonb
                        END) key_value,
                    jsonb_array_elements(
                        CASE WHEN jsonb_typeof(value) = 'array'
                            AND jsonb_typeof(value -> 0) = 'object' THEN
                            value
                        ELSE
                            '[]'::jsonb
                        END) "array_value"
                FROM
                    all_paths) a))
SELECT
    path,
    object_property,
    array_item,
    value
FROM
    all_paths;

$$;

