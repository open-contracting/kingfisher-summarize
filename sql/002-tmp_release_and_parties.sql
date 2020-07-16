
drop view if exists tmp_release_summary_with_release_data;
drop table if exists tmp_release_summary;

create table tmp_release_summary
AS
select 
    r.id::bigint * 10 AS id,
    'release' AS release_type,
    r.id AS table_id,
    collection_id,
    ocid,
    release_id,
    data_id,
    package_data_id,
    coalesce(pd.data ->> 'version', '1.0') AS package_version,
    convert_to_timestamp(d.data ->> 'date') release_date,
    d.data -> 'tag' release_tag,
    d.data ->> 'language' release_language
from 
    release AS r
join
    package_data pd on pd.id = r.package_data_id
join
    data d on d.id = r.data_id
join
    collection c on c.id = r.collection_id
where
    collection_id in (select id from selected_collections)

union

select 
    r.id::bigint * 10 + 1 AS id,
    'record' as release_type,
    r.id AS table_id, 
    collection_id,
    ocid,
    null AS release_id,
    data_id,
    package_data_id,
    coalesce(pd.data ->> 'version', '1.0') AS package_version,
    convert_to_timestamp(d.data -> 'compiledRelease' ->> 'date') release_date,
    d.data -> 'compiledRelease' -> 'tag' release_tag,
    d.data -> 'compiledRelease' ->> 'language' release_language
from 
    record AS r
join
    package_data pd on pd.id = r.package_data_id
join
    data d on d.id = r.data_id
join
    collection c on c.id = r.collection_id
where
    collection_id in (select id from selected_collections)

union

select 
    r.id::bigint * 10 + 2 AS id,
    'compiled_release' as release_type,
    r.id AS table_id,
    collection_id,
    ocid,
    null AS release_id,
    data_id,
    --Kingfisher Process’ compiled_release table has no package_data_id column, so setting package_data_id to null.
    null AS package_data_id,
    null AS package_version,  -- this would be useful but hard to get
    convert_to_timestamp(d.data ->> 'date') release_date,
    d.data -> 'tag' release_tag,
    d.data ->> 'language' release_language
from
    compiled_release AS r
join
    data d on d.id = r.data_id
where
    collection_id in (select id from selected_collections)

union

select
    (r.id::bigint * 1000000 + (ordinality - 1)) * 10 + 3 AS id,
    'embedded_release' as release_type,
    r.id AS table_id,
    collection_id,
    ocid,
    value ->> 'id' AS release_id,
    data_id,
    package_data_id,
    coalesce(pd.data ->> 'version', '1.0') AS package_version,
    convert_to_timestamp(value ->> 'date') release_date,
    value -> 'tag' release_tag,
    value ->> 'language' release_language
from
    record AS r
join
    package_data pd on pd.id = r.package_data_id
join
    data d on d.id = r.data_id
join
    collection c on c.id = r.collection_id
cross join
    jsonb_array_elements(d.data -> 'releases') with ordinality
where
    -- We only want embedded releases, not linked releases
    (value -> 'id') is not null
     and
    collection_id in (select id from selected_collections)

;

create unique index tmp_release_summary_id on tmp_release_summary(id);
create index tmp_release_summary_data_id on tmp_release_summary(data_id);
create index tmp_release_summary_package_data_id on tmp_release_summary(package_data_id);
create index tmp_release_summary_collection_id on tmp_release_summary(collection_id);



create or replace view tmp_release_summary_with_release_data
as
select 
    case
        when release_type = 'record' then d.data -> 'compiledRelease'
        when release_type = 'embedded_release' then d.data -> 'releases' -> (mod(r.id / 10, 1000000)::integer)
        else d.data end AS data,
    r.*  
from 
    tmp_release_summary AS r
join
    data d on d.id = r.data_id;

----

drop table if exists staged_parties_summary_no_data;

create table staged_parties_summary_no_data
AS
select 
    r.id,
    ordinality - 1 AS party_index,
	release_type,
    collection_id,
    ocid,
    release_id,
    data_id,
    value ->> 'id' AS parties_id,   
    value -> 'roles' AS roles,
    (value -> 'identifier' ->> 'scheme') || '-' || (value -> 'identifier' ->> 'id') AS identifier,
    coalesce(
        value ->> 'id',
        (value -> 'identifier' ->> 'scheme') || '-' || (value -> 'identifier' ->> 'id'),
        value ->> 'name'
    ) AS unique_identifier_attempt,
    (select 
        jsonb_agg((additional_identifier ->> 'scheme') || '-' || (additional_identifier ->> 'id'))
    from
        jsonb_array_elements(case when jsonb_typeof(value->'additionalIdentifiers') = 'array' then value->'additionalIdentifiers' else '[]'::jsonb end) additional_identifier
    where
        additional_identifier ?& array['scheme', 'id']											   
    ) parties_additionalIdentifiers_ids,
    jsonb_array_length(case when jsonb_typeof(value->'additionalIdentifiers') = 'array' then value->'additionalIdentifiers' else '[]'::jsonb end) parties_additionalIdentifiers_count
from 
    tmp_release_summary_with_release_data AS r
cross join
    jsonb_array_elements(data -> 'parties') with ordinality
where
    jsonb_typeof(data -> 'parties') = 'array';

----

drop view if exists parties_summary;
drop table if exists parties_summary_no_data;

create table parties_summary_no_data
AS
select * from staged_parties_summary_no_data;

drop table staged_parties_summary_no_data;

create unique index parties_summary_no_data_id on parties_summary_no_data(id, party_index);
create index parties_summary_no_data_data_id on parties_summary_no_data(data_id);
create index parties_summary_no_data_collection_id on parties_summary_no_data(collection_id);
create index parties_summary_no_data_party_id on parties_summary_no_data(id, parties_id);


create view parties_summary
AS
select 
    parties_summary_no_data.*, 
    case when
        release_type = 'record'
    then
        data #> ARRAY['compiledRelease', 'parties', party_index::text]
    when
        release_type = 'embedded_release'
    then
        data -> 'releases' -> (mod(parties_summary_no_data.id / 10, 1000000)::integer) -> 'parties' -> party_index::integer
    else
        data #> ARRAY['parties', party_index::text]
    end as party
from 
    parties_summary_no_data
join
    data on data.id = data_id;


-- The following pgpsql makes indexes on parties_summary only if it is a table and not a view,
-- you will need to run --tables-only command line parameter to allow this to run. 

DO
$$
DECLARE query text;

BEGIN
    query :=
        $query$
            create unique index parties_summary_id on parties_summary(id, party_index);
            create index parties_summary_data_id on parties_summary(data_id);
            create index parties_summary_collection_id on parties_summary(collection_id);
            create index parties_summary_party_id on parties_summary(id, parties_id);
        $query$
    ;
    execute query;
EXCEPTION 
    WHEN wrong_object_type THEN null;
END;
$$;
