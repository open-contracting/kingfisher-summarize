-- Inspired by https://github.com/csikfer/lanview2/blob/master/database/update-1.9.sql
-- Reference:
-- https://www.postgresql.org/docs/current/parallel-safety.html
-- https://www.postgresql.org/docs/current/errcodes-appendix.html

CREATE FUNCTION convert_to_numeric (text)
RETURNS numeric
AS $$
    BEGIN
        RETURN CAST($1 AS numeric);
    EXCEPTION
        WHEN invalid_text_representation THEN
            RETURN NULL;
    END;
$$
LANGUAGE plpgsql
IMMUTABLE
STRICT
PARALLEL UNSAFE;

CREATE FUNCTION convert_to_timestamp (text)
RETURNS timestamp
AS $$
    BEGIN
        RETURN CAST($1 AS timestamp);
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
-- https://stackoverflow.com/questions/12310986/combine-two-columns-and-add-into-one-new-column
CREATE FUNCTION hyphenate (text, text)
RETURNS text
AS $$
    SELECT CASE
    WHEN $1 IS NULL THEN $2
    WHEN $2 IS NULL THEN $1
    ELSE $1 || '-' || $2
    END
$$
LANGUAGE sql
IMMUTABLE
PARALLEL SAFE;

