
drop table if exists staged_buyer_summary;

create table staged_buyer_summary
AS
with 
    r AS (
    select 
        *,
        data -> 'buyer' as buyer 
     from 
        tmp_release_summary_with_release_data
    ) 
select
    distinct on (r.id)
    r.id,
    r.release_type,
    r.collection_id,
    r.ocid,
    r.release_id,
    r.data_id,
    buyer,
    buyer ->> 'id' AS buyer_parties_id,
    (buyer -> 'identifier' ->> 'scheme') || '-' || (buyer -> 'identifier' ->> 'id') AS buyer_identifier,
    coalesce(
        buyer ->> 'id',
        (buyer -> 'identifier' ->> 'scheme') || '-' || (buyer -> 'identifier' ->> 'id'),
        buyer ->> 'name'
    ) AS unique_identifier_attempt,
    (select 
        jsonb_agg((additional_identifier ->> 'scheme') || '-' || (additional_identifier ->> 'id'))
    from
        jsonb_array_elements(case when jsonb_typeof(buyer -> 'additionalIdentifiers') = 'array' then buyer -> 'additionalIdentifiers' else '[]'::jsonb end) additional_identifier
    where
        additional_identifier::jsonb ?& array['scheme', 'id']											   
    ) buyer_additionalIdentifiers_ids,
    jsonb_array_length(case when jsonb_typeof(buyer -> 'additionalIdentifiers') = 'array' then buyer -> 'additionalIdentifiers' else '[]'::jsonb end) buyer_additionalIdentifiers_count,
    case when ps.id is not null then 1 else 0 end link_to_parties,
    case when ps.id is not null and (ps.party -> 'roles') ? 'buyer' then 1 else 0 end link_with_role,
    ps.party_index
from r
left join
    parties_summary ps on r.id = ps.id and (buyer ->> 'id') = ps.parties_id
where buyer is not null
;

----

drop table if exists buyer_summary;

create table buyer_summary
AS
select * from staged_buyer_summary;

drop table if exists staged_buyer_summary;


create unique index buyer_summary_id on buyer_summary(id);
create index buyer_summary_data_id on buyer_summary(data_id);
create index buyer_summary_collection_id on buyer_summary(collection_id);

----

drop table if exists staged_procuringEntity_summary;

create table staged_procuringEntity_summary
AS
with 
r AS (
    select 
        *,
        data -> 'tender' -> 'procuringEntity' as procuringEntity 
    from 
        tmp_release_summary_with_release_data)
select
    distinct on (r.id)
    r.id,
    r.release_type,
    r.collection_id,
    r.ocid,
    r.release_id,
    r.data_id,
    procuringEntity,
    procuringEntity ->> 'id' AS procuringEntity_parties_id,
    (procuringEntity -> 'identifier' ->> 'scheme') || '-' || (procuringEntity -> 'identifier' ->> 'id') AS procuringEntity_identifier,
    coalesce(
        procuringEntity ->> 'id',
        (procuringEntity -> 'identifier' ->> 'scheme') || '-' || (procuringEntity -> 'identifier' ->> 'id'),
        procuringEntity ->> 'name'
    ) AS unique_identifier_attempt,
    (select 
        jsonb_agg((additional_identifier ->> 'scheme') || '-' || (additional_identifier ->> 'id'))
    from
        jsonb_array_elements(case when jsonb_typeof(procuringEntity -> 'additionalIdentifiers') = 'array' then procuringEntity -> 'additionalIdentifiers' else '[]'::jsonb end) additional_identifier
    where
        additional_identifier::jsonb ?& array['scheme', 'id']											   
    ) procuringEntity_additionalIdentifiers_ids,
    jsonb_array_length(case when jsonb_typeof(procuringEntity -> 'additionalIdentifiers') = 'array' then procuringEntity -> 'additionalIdentifiers' else '[]'::jsonb end) procuringEntity_additionalIdentifiers_count,
    case when ps.id is not null then 1 else 0 end link_to_parties,
    case when ps.id is not null and (ps.party -> 'roles') ? 'procuringEntity' then 1 else 0 end link_with_role,
    ps.party_index
from 
    r
left join
    parties_summary ps on r.id = ps.id and (procuringEntity ->> 'id') = ps.parties_id
where procuringEntity is not null
;

----

drop table if exists procuringEntity_summary;

create table procuringEntity_summary
AS
select * from staged_procuringEntity_summary;

drop table if exists staged_procuringEntity_summary;

create unique index procuringEntity_summary_id on procuringEntity_summary(id);
create index procuringEntity_summary_data_id on procuringEntity_summary(data_id);
create index procuringEntity_summary_collection_id on procuringEntity_summary(collection_id);


----

drop table if exists staged_tenderers_summary;

create table staged_tenderers_summary
AS
with 
r AS (
    select 
        rs.*,
        value as tenderer,
        ordinality - 1 as tenderer_index
    from 
        tmp_release_summary_with_release_data rs
    cross join
        jsonb_array_elements(data -> 'tender' -> 'tenderers') with ordinality
    where
        jsonb_typeof(data -> 'tender' -> 'tenderers') = 'array')
select
    distinct on (r.id, tenderer_index)
    r.id,
    tenderer_index,
	r.release_type,
    r.collection_id,
    r.ocid,
    r.release_id,
    r.data_id,
    tenderer,
    tenderer ->> 'id' AS tenderer_parties_id,
	(tenderer -> 'identifier' ->> 'scheme') || '-' || (tenderer -> 'identifier' ->> 'id') AS tenderer_identifier,
    coalesce(
        tenderer ->> 'id',
        (tenderer -> 'identifier' ->> 'scheme') || '-' || (tenderer -> 'identifier' ->> 'id'),
        tenderer ->> 'name'
    ) AS unique_identifier_attempt,
    (select 
        jsonb_agg((additional_identifier ->> 'scheme') || '-' || (additional_identifier ->> 'id'))
    from
        jsonb_array_elements(case when jsonb_typeof(tenderer -> 'additionalIdentifiers') = 'array' then tenderer -> 'additionalIdentifiers' else '[]'::jsonb end) additional_identifier
    where
        additional_identifier::jsonb ?& array['scheme', 'id']											   
    ) tenderer_additionalIdentifiers_ids,
    jsonb_array_length(case when jsonb_typeof(tenderer -> 'additionalIdentifiers') = 'array' then tenderer -> 'additionalIdentifiers' else '[]'::jsonb end) tenderer_additionalIdentifiers_count,
    case when ps.id is not null then 1 else 0 end link_to_parties,
    case when ps.id is not null and (ps.party -> 'roles') ? 'tenderer' then 1 else 0 end link_with_role,
    ps.party_index
from 
    r
left join
    parties_summary ps on r.id = ps.id and (tenderer ->> 'id') = ps.parties_id
where tenderer is not null
;

----


drop table if exists tenderers_summary;

create table tenderers_summary
AS
select * from staged_tenderers_summary;

drop table if exists staged_tenderers_summary;


create unique index tenderers_summary_id on tenderers_summary(id, tenderer_index);
create index tenderers_summary_data_id on tenderers_summary(data_id);
create index tenderers_summary_collection_id on tenderers_summary(collection_id);

