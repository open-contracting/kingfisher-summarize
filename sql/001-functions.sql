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
        CASE WHEN v_input ~ '^\d{4}-\d\d-\d\d[Tt ]\d\d:\d\d:\d\d(\.\d+)?(([+-]\d\d:\d\d)|[Zz])?$' THEN
            v_input::timestamp
        ELSE
            NULL
        END;

$$;

