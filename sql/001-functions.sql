CREATE OR REPLACE FUNCTION convert_to_numeric(
	v_input text)
    RETURNS numeric
    LANGUAGE 'sql'
    PARALLEL SAFE
AS 
$$
    select case when length(v_input) > 20 then 0 else to_number('0'||v_input, '99999999999999999999.99') end;
$$;

CREATE OR REPLACE FUNCTION convert_to_timestamp(
	v_input text)
    RETURNS timestamp
    LANGUAGE 'sql'
    PARALLEL SAFE
AS 
$$
    select case when v_input ~ '^\d{4}-\d\d-\d\d[Tt ]\d\d:\d\d:\d\d(\.\d+)?(([+-]\d\d:\d\d)|[Zz])?$' then v_input::timestamp else null end;
$$;
