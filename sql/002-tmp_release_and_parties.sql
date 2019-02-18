set search_path = views, public;

drop materialized view if exists tmp_release_summary cascade;

create materialized view tmp_release_summary
as
select 
    r.id * 10 AS id,
    'release' AS release_type,
    r.id AS table_id,
    collection_id,
    ocid,
    release_id,
    data_id,
    package_data_id,
    coalesce(pd.data ->> 'version', '1.0') AS package_version,
    convert_to_timestamp(d.data ->> 'date') release_date,
    d.data -> 'tag' release_tag
from 
    release_with_collection AS r
join
    package_data pd on pd.id = r.package_data_id
join
    data d on d.id = r.data_id

union

select 
    r.id * 10 + 1 AS id,
    'record' as release_type,
    r.id AS table_id, 
    collection_id,
    ocid,
    null AS release_id,
    data_id,
    package_data_id,
    coalesce(pd.data ->> 'version', '1.0') AS package_version,
    convert_to_timestamp(d.data -> 'compiledRelease' ->> 'date') release_date,
    d.data -> 'compliedRelease' -> 'tag' release_tag
from 
    record_with_collection AS r
join
    package_data pd on pd.id = r.package_data_id
join
    data d on d.id = r.data_id

union

select 
    r.id * 10 + 2 AS id,
    'compiled_release' as release_type,
    r.id AS table_id,
    collection_id,
    ocid,
    null AS release_id,
    data_id,
    null AS package_data_id,
    null AS package_version,  -- this would be useful but hard to get
    convert_to_timestamp(d.data ->> 'date') release_date,
    d.data -> 'tag' release_tag
from 
    compiled_release_with_collection AS r
join
    data d on d.id = r.data_id
with no data;

create unique index tmp_release_summary_id on tmp_release_summary(id);
create index tmp_release_summary_data_id on tmp_release_summary(data_id);
create index tmp_release_summary_package_data_id on tmp_release_summary(package_data_id);
create index tmp_release_summary_collection_id on tmp_release_summary(collection_id);


create view tmp_release_summary_with_release_data
as
select 
    case when release_type = 'record' then d.data -> 'compiledRelease' else d.data end AS data,
    r.*  
from 
    tmp_release_summary AS r
join
    data d on d.id = r.data_id;


create materialized view parties_summary
as
select 
    r.id,
    ordinality - 1 AS party_index,
	release_type,
    collection_id,
    ocid,
    release_id,
    data_id,
    value AS party,   
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
    jsonb_array_elements(data -> 'parties') with ordinality AS parties
where
    jsonb_typeof(data -> 'parties') = 'array'
with no data;


create unique index parties_summary_id on parties_summary(id, party_index);
create index parties_summary_data_id on parties_summary(data_id);
create index parties_summary_collection_id on parties_summary(collection_id);
create index parties_summary_party_id on parties_summary(id, parties_id);

--refresh materialized view tmp_release_summary;
--refresh materialized view parties_summary;

