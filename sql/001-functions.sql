
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


drop function if exists flatten;

CREATE OR REPLACE FUNCTION flatten(jsonb)
    RETURNS TABLE(path text, object_property integer, array_item integer) 
    LANGUAGE 'sql'
    PARALLEL SAFE
AS
$$
WITH RECURSIVE all_paths(path, "value", "object_property", "array_item") AS (
    select 
		 key "path", 
         value "value", 
         1 "object_property",
         0 "array_item"
    from 
         jsonb_each($1)
    UNION ALL (
        select 
            case when key_value is not null then
                path || '/'::text || (key_value).key::text
            else
                path
            end "path",
            case when key_value is not null then
                (key_value).value
            else
                array_value
            end "value",
            case when key_value is not null then 1 else 0 end,
            case when key_value is null then 1 else 0 end
       from
          (select 
             path,
             jsonb_each(case when jsonb_typeof(value) = 'object' then value else '{}'::jsonb end) key_value,
             jsonb_array_elements(case when jsonb_typeof(value) = 'array' and jsonb_typeof(value -> 0) = 'object' then value else '[]'::jsonb end) "array_value"
             from all_paths
          ) a
     )
  )
  SELECT path, object_property, array_item FROM all_paths;
$$;	


drop function if exists flatten_with_values;

CREATE OR REPLACE FUNCTION flatten_with_values(jsonb)
    RETURNS TABLE(path text, object_property integer, array_item integer, value jsonb) 
    LANGUAGE 'sql'
    PARALLEL SAFE
AS
$$
WITH RECURSIVE all_paths(path, "value", "object_property", "array_item") AS (
    select 
		 key "path", 
         value "value", 
         1 "object_property",
         0 "array_item"
    from 
         jsonb_each($1)
    UNION ALL (
        select 
            case when key_value is not null then
                path || '/'::text || (key_value).key::text
            else
                path
            end "path",
            case when key_value is not null then
                (key_value).value
            else
                array_value
            end "value",
            case when key_value is not null then 1 else 0 end,
            case when key_value is null then 1 else 0 end
       from
          (select 
             path,
             jsonb_each(case when jsonb_typeof(value) = 'object' then value else '{}'::jsonb end) key_value,
             jsonb_array_elements(case when jsonb_typeof(value) = 'array' and jsonb_typeof(value -> 0) = 'object' then value else '[]'::jsonb end) "array_value"
             from all_paths
          ) a
     )
  )
  SELECT path, object_property, array_item, value FROM all_paths;
$$;	
