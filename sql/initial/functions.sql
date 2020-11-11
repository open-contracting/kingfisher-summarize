-- Inspired by https://github.com/csikfer/lanview2/blob/master/database/update-1.9.sql
-- Error reference: https://www.postgresql.org/docs/current/errcodes-appendix.html

CREATE FUNCTION convert_to_numeric (text)
    RETURNS numeric PARALLEL SAFE
    AS $$
BEGIN
    RETURN CAST($1 AS numeric);
EXCEPTION
    WHEN invalid_text_representation THEN
        RETURN NULL;
END;

$$
LANGUAGE plpgsql
IMMUTABLE STRICT;

CREATE FUNCTION convert_to_timestamp (text)
    RETURNS timestamp PARALLEL SAFE
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
IMMUTABLE STRICT;

CREATE FUNCTION hyphenate (text, text)
    RETURNS text PARALLEL SAFE
    AS $$
BEGIN
    IF $1 IS NULL AND $2 IS NULL THEN
        RETURN NULL;
    ELSE
        RETURN concat_ws('-', $1, $2);
    END IF;
END;

$$
LANGUAGE plpgsql
IMMUTABLE;

