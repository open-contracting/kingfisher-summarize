
drop table if exists tmp_awards_summary;

create table tmp_awards_summary
AS
select
    r.id,
    award_index,
    r.release_type,
    r.collection_id,
    r.ocid,
    r.release_id,
    r.data_id,
    award
from
    (select 
        rs.*,
        ordinality - 1 AS award_index,
        value as award
    from 
        tmp_release_summary_with_release_data rs 
    cross join
        jsonb_array_elements(data -> 'awards') with ordinality
    where jsonb_typeof(data -> 'awards') = 'array'
    ) AS r
;

create unique index tmp_awards_summary_id on tmp_awards_summary(id, award_index);

----

drop table if exists staged_award_suppliers_summary;

create table staged_award_suppliers_summary
AS
select
    distinct on (r.id, award_index, supplier_index)
    r.id,
    award_index,
    supplier_index,
	r.release_type,
    r.collection_id,
    r.ocid,
    r.release_id,
    r.data_id,
    supplier,
    supplier ->> 'id' AS supplier_parties_id,
	(supplier -> 'identifier' ->> 'scheme') || '-' || (supplier -> 'identifier' ->> 'id') AS supplier_identifier,
    coalesce(
        supplier ->> 'id',
        (supplier -> 'identifier' ->> 'scheme') || '-' || (supplier -> 'identifier' ->> 'id'),
        supplier ->> 'name'
    ) AS unique_identifier_attempt,
    (select 
        jsonb_agg((additional_identifier ->> 'scheme') || '-' || (additional_identifier ->> 'id'))
    from
        jsonb_array_elements(case when jsonb_typeof(supplier -> 'additionalIdentifiers') = 'array' then supplier -> 'additionalIdentifiers' else '[]'::jsonb end) additional_identifier
    where
        additional_identifier::jsonb ?& array['scheme', 'id']											   
    ) supplier_additionalIdentifiers_ids,
    jsonb_array_length(case when jsonb_typeof(supplier -> 'additionalIdentifiers') = 'array' then supplier -> 'additionalIdentifiers' else '[]'::jsonb end) supplier_additionalIdentifiers_count,
    case when ps.id is not null then 1 else 0 end link_to_parties,
    case when ps.id is not null and (ps.party -> 'roles') ? 'supplier' then 1 else 0 end link_with_role,
    ps.party_index
from 
    (select 
        tas.*,
        value As supplier,
        ordinality - 1 AS supplier_index
    from 
        tmp_awards_summary tas
    cross join
        jsonb_array_elements(award -> 'suppliers') with ordinality
    where
        jsonb_typeof(award -> 'suppliers') = 'array'
    ) AS r
left join
    parties_summary ps on r.id = ps.id and (supplier ->> 'id') = ps.parties_id
where supplier is not null
;

----

drop table if exists award_suppliers_summary;

create table award_suppliers_summary
AS
select * from staged_award_suppliers_summary;

drop table if exists staged_award_suppliers_summary;


create unique index award_suppliers_summary_id on award_suppliers_summary(id, award_index, supplier_index);
create index award_suppliers_summary_data_id on award_suppliers_summary(data_id);
create index award_suppliers_summary_collection_id on award_suppliers_summary(collection_id);

----

drop table if exists staged_award_documents_summary;

create table staged_award_documents_summary
AS
select
    r.id,
    award_index,
    document_index,
    r.release_type,
    r.collection_id,
    r.ocid,
    r.release_id,
    r.data_id,
    document,
    document ->> 'documentType' as documentType,
    document ->> 'format' as format
from
    (select 
        tas.*,
        value AS document,
        ordinality -1 AS document_index 
    from 
        tmp_awards_summary tas 
    cross join
        jsonb_array_elements(award -> 'documents') with ordinality
    where jsonb_typeof(award -> 'documents') = 'array'
    ) AS r
;

----

drop table if exists award_documents_summary;

create table award_documents_summary
AS
select * from staged_award_documents_summary;

drop table if exists staged_award_documents_summary;


create unique index award_documents_summary_id on award_documents_summary(id, award_index, document_index);
create index award_documents_summary_data_id on award_documents_summary(data_id);
create index award_documents_summary_collection_id on award_documents_summary(collection_id);

----

drop table if exists staged_award_items_summary;

create table staged_award_items_summary
AS
select
    r.id,
    award_index,
    item_index,
    r.release_type,
    r.collection_id,
    r.ocid,
    r.release_id,
    r.data_id,
    item,
    item ->> 'id' item_id,
    convert_to_numeric(item ->> 'quantity') quantity,
    convert_to_numeric(unit -> 'value' ->> 'amount') unit_amount,
    unit -> 'value' ->> 'currency' unit_currency,
	(item -> 'classification' ->> 'scheme') || '-' || (item -> 'classification' ->> 'id') AS item_classification,
    (select 
        jsonb_agg((additional_classification ->> 'scheme') || '-' || (additional_classification ->> 'id'))
    from
        jsonb_array_elements(case when jsonb_typeof(item->'additionalClassifications') = 'array' then item->'additionalClassifications' else '[]'::jsonb end) additional_classification
    where
        additional_classification ?& array['scheme', 'id']											   
    ) item_additionalIdentifiers_ids,
    jsonb_array_length(case when jsonb_typeof(item->'additionalClassifications') = 'array' then item->'additionalClassifications' else '[]'::jsonb end) as additional_classification_count
from
    (select 
        tas.*,
        value AS item,
        value -> 'unit' AS unit,
        ordinality -1 AS item_index 
    from 
        tmp_awards_summary tas 
    cross join
        jsonb_array_elements(award -> 'items') with ordinality
    where jsonb_typeof(award -> 'items') = 'array'
    ) AS r
;

----

drop table if exists award_items_summary;

create table award_items_summary
AS
select * from staged_award_items_summary;

drop table if exists staged_award_items_summary;

create unique index award_items_summary_id on award_items_summary(id, award_index, item_index);
create index award_items_summary_data_id on award_items_summary(data_id);
create index award_items_summary_collection_id on award_items_summary(collection_id);

----

drop table if exists staged_awards_summary_no_data;

create table staged_awards_summary_no_data
AS
select
    r.id,
    r.award_index,
    r.release_type,
    r.collection_id,
    r.ocid,
    r.release_id,
    r.data_id,
    award ->> 'id' AS award_id,
    award ->> 'title' AS award_title,
    award ->> 'status' AS award_status,
    convert_to_numeric(award -> 'value' ->> 'amount') AS award_value_amount,
    award -> 'value' ->> 'currency' AS award_value_currency,
    convert_to_timestamp(award ->> 'date') AS award_date,

    convert_to_timestamp(award -> 'contractPeriod' ->> 'startDate') AS award_contractPeriod_startDate,
    convert_to_timestamp(award -> 'contractPeriod' ->> 'endDate') AS award_contractPeriod_endDate,
    convert_to_timestamp(award -> 'contractPeriod' ->> 'maxExtentDate') AS award_contractPeriod_maxExtentDate,
    convert_to_numeric(award -> 'contractPeriod' ->> 'durationInDays') AS award_contractPeriod_durationInDays,
    jsonb_array_length(case when jsonb_typeof(award->'suppliers') = 'array' then award->'suppliers' else '[]'::jsonb end) as suppliers_count,
    documents_count,
    documentType_counts,
    items_count
from
    tmp_awards_summary r
left join
    (
    select 
        id, 
        award_index,
        jsonb_object_agg(coalesce(documentType, ''), documentType_count) documentType_counts, 
        count(*) documents_count
    from
        (select 
            id, award_index, documentType, count(*) documentType_count
        from
            award_documents_summary
        group by
            id, award_index, documentType
        ) AS d
    group by id, award_index
    ) documentType_counts
    using (id, award_index)
left join
    (
    select 
        id, 
        award_index,
        count(*) items_count
    from
        award_items_summary
    group by id, award_index
    ) items_counts
    using (id, award_index)
;

----

drop view if exists awards_summary;

drop table if exists awards_summary_no_data;

create table awards_summary_no_data
AS
select * from staged_awards_summary_no_data;

drop table if exists staged_awards_summary_no_data;

create unique index awards_summary_id on awards_summary_no_data(id, award_index);
create index awards_summary_data_id on awards_summary_no_data(data_id);
create index awards_summary_collection_id on awards_summary_no_data(collection_id);

create view awards_summary
AS
select 
    awards_summary_no_data.*, 
    data #> ARRAY['awards', award_index::text] as award
from 
    awards_summary_no_data
join
    data on data.id = data_id;

drop table if exists tmp_awards_summary;
