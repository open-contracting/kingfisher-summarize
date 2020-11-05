-- https://github.com/csikfer/lanview2/blob/master/database/update-1.9.sql
CREATE FUNCTION convert_to_numeric (text, numeric DEFAULT NULL)
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

CREATE FUNCTION convert_to_timestamp (text, timestamp DEFAULT NULL)
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

-- Reference:
-- https://www.postgresql.org/docs/current/errcodes-appendix.html
