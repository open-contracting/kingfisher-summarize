-- Inspired by https://github.com/csikfer/lanview2/blob/master/database/update-1.9.sql
-- https://www.postgresql.org/docs/11/sql-createfunction.html
-- https://www.postgresql.org/docs/11/parallel-safety.html

CREATE FUNCTION convert_to_numeric (text)
RETURNS numeric
AS $$
    SELECT
        CASE WHEN $1 ~ '^-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE][+-]?\d+)?$' THEN
            $1::numeric
        ELSE
            NULL
        END
$$
LANGUAGE sql
IMMUTABLE
STRICT
PARALLEL SAFE;

-- UNSAFE due to EXCEPTION block.
-- https://www.postgresql.org/docs/11/errcodes-appendix.html
CREATE FUNCTION convert_to_timestamp (text)
RETURNS timestamp
AS $$
    BEGIN
        RETURN $1::timestamp;
    EXCEPTION
        WHEN invalid_datetime_format THEN
            RETURN NULL;
        WHEN datetime_field_overflow THEN
            RETURN NULL;
    END;
$$
LANGUAGE plpgsql
IMMUTABLE
STRICT
PARALLEL UNSAFE;

-- concat() and concat_ws() are STABLE not IMMUTABLE.
-- Not STRICT as NULL inputs are expected.
-- https://stackoverflow.com/a/12320369/244258
CREATE FUNCTION hyphenate (text, text)
RETURNS text
AS $$
    SELECT
        CASE WHEN $1 IS NULL THEN
            $2
        WHEN $2 IS NULL THEN
            $1
        ELSE
            $1 || '-' || $2
        END
$$
LANGUAGE sql
IMMUTABLE
PARALLEL SAFE;

