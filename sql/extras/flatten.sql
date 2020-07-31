CREATE OR REPLACE FUNCTION flatten (jsonb)
    RETURNS TABLE (
        path text,
        object_property integer,
        array_item integer)
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
    array_item
FROM
    all_paths;

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

