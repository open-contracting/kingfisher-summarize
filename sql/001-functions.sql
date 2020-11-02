CREATE OR REPLACE FUNCTION convert_to_numeric (v_input text)
    RETURNS numeric
    LANGUAGE 'sql'
    PARALLEL SAFE
    AS $$
    SELECT
        CASE WHEN length(v_input) > 20 THEN
            0
        ELSE
            to_number('0' || v_input, '99999999999999999999.99')
        END;

$$;

CREATE OR REPLACE FUNCTION convert_to_timestamp (v_input text)
    RETURNS timestamp
    LANGUAGE 'sql'
    PARALLEL SAFE
    AS $$
    SELECT
        CASE WHEN v_input ~ '^0000' THEN
            NULL
        WHEN v_input ~ '^\d{4}-\d\d-\d\d[Tt ]\d\d:\d\d:\d\d(\.\d+)?(([+-]\d\d:\d\d)|[Zz])?$' THEN
            v_input::timestamp
        ELSE
            NULL
        END;

$$;

-- https://stackoverflow.com/a/463314/244258
CREATE OR REPLACE FUNCTION drop_table_or_view (object_name text)
    RETURNS integer
    AS $$
DECLARE
    is_table integer;
    is_view integer;
BEGIN
    SELECT
        INTO is_table count(*)
    FROM
        pg_tables
    WHERE
        tablename = object_name;
    SELECT
        INTO is_view count(*)
    FROM
        pg_views
    WHERE
        viewname = object_name;
    IF is_table = 1 THEN
        EXECUTE 'DROP TABLE ' || object_name;
        RETURN 1;
    END IF;
    IF is_view = 1 THEN
        EXECUTE 'DROP VIEW ' || object_name;
        RETURN 2;
    END IF;
    RETURN 0;
END;
$$
LANGUAGE plpgsql;

