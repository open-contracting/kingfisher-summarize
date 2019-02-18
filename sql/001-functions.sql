set search_path = views, public;

CREATE OR REPLACE FUNCTION convert_to_numeric(
	v_input text)
    RETURNS numeric
    LANGUAGE 'plpgsql'
    PARALLEL SAFE
AS 
$$
    DECLARE v_num_value NUMERIC DEFAULT NULL;
    BEGIN
        BEGIN
            v_num_value := v_input::NUMERIC;
        EXCEPTION WHEN OTHERS THEN
            RETURN NULL;
        END;
    RETURN v_num_value;
    END;
$$;

CREATE OR REPLACE FUNCTION convert_to_timestamp(
	v_input text)
    RETURNS timestamp
    LANGUAGE 'plpgsql'
    PARALLEL SAFE
AS 
$$
    DECLARE v_timestamp timestamp DEFAULT NULL;
    BEGIN
        BEGIN
            v_timestamp := v_input::timestamp;
        EXCEPTION WHEN OTHERS THEN
            RETURN NULL;
        END;
    RETURN v_timestamp;
    END;
$$;


CREATE OR REPLACE FUNCTION flatten(jsonb)
    RETURNS TABLE(path text, value jsonb, object_property integer, array_item integer) 
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
  SELECT path, "value", object_property, array_item FROM all_paths;
$$;	

