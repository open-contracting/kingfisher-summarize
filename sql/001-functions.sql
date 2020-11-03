-- https://github.com/csikfer/lanview2/blob/master/database/update-1.9.sql
CREATE OR REPLACE FUNCTION convert_to_numeric (text, numeric DEFAULT NULL)
    RETURNS numeric PARALLEL SAFE
    AS $$
BEGIN
    RETURN CAST($1 AS numeric);
EXCEPTION
    WHEN invalid_text_representation THEN
        RETURN $2;
END;

$$
LANGUAGE plpgsql
IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION convert_to_timestamp (text, timestamp DEFAULT NULL)
    RETURNS timestamp PARALLEL SAFE
    AS $$
BEGIN
    RETURN CAST($1 AS timestamp);
EXCEPTION
    WHEN invalid_datetime_format THEN
        RETURN $2;
    WHEN datetime_field_overflow THEN
        RETURN $2;
END;

$$
LANGUAGE plpgsql
IMMUTABLE STRICT;

-- https://stackoverflow.com/a/463314/244258
CREATE OR REPLACE FUNCTION drop_table_or_view (object_name text)
    RETURNS integer PARALLEL UNSAFE
    AS $$
DECLARE
    is_table integer;
    is_view integer;
BEGIN
    EXECUTE 'DROP VIEW IF EXISTS ' || object_name;
    RETURN 1;
EXCEPTION
    WHEN wrong_object_type THEN
        EXECUTE 'DROP TABLE IF EXISTS ' || object_name;
        RETURN 2;
END;

$$
LANGUAGE plpgsql
VOLATILE;

-- Reference:
-- https://www.postgresql.org/docs/current/errcodes-appendix.html
