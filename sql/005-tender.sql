
drop table if exists tmp_tender_summary;

create table tmp_tender_summary
AS
select
    r.id,
    r.release_type,
    r.collection_id,
    r.ocid,
    r.release_id,
    r.data_id,
    tender
from
    (select 
        data -> 'tender' AS tender, 
        rs.* 
    from 
        tmp_release_summary_with_release_data rs where data ? 'tender'
    ) AS r
;

create unique index tmp_tender_summary_id on tmp_tender_summary(id);

----

drop table if exists staged_tender_documents_summary;

create table staged_tender_documents_summary
AS
select
    r.id,
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
        tps.*,
        value AS document,
        ordinality -1 AS document_index 
    from 
        tmp_tender_summary tps 
    cross join
        jsonb_array_elements(tender -> 'documents') with ordinality
    where jsonb_typeof(tender -> 'documents') = 'array'
    ) AS r
;

----

drop table if exists tender_documents_summary;

create table tender_documents_summary
AS
select * from staged_tender_documents_summary;

drop table if exists staged_tender_documents_summary;

create unique index tender_documents_summary_id on tender_documents_summary(id, document_index);
create index tender_documents_summary_data_id on tender_documents_summary(data_id);
create index tender_documents_summary_collection_id on tender_documents_summary(collection_id);


----

drop table if exists staged_tender_milestones_summary;

create table staged_tender_milestones_summary
AS
select
    r.id,
    milestone_index,
    r.release_type,
    r.collection_id,
    r.ocid,
    r.release_id,
    r.data_id,
    milestone,
    milestone ->> 'type' as type,
    milestone ->> 'code' as code,  
    milestone ->> 'status' as status
from
    (select 
        tps.*,
        value AS milestone,
        ordinality -1 AS milestone_index 
    from 
        tmp_tender_summary tps 
    cross join
        jsonb_array_elements(tender -> 'milestones') with ordinality
    where jsonb_typeof(tender -> 'milestones') = 'array'
    ) AS r
;

----

drop table if exists tender_milestones_summary;

create table tender_milestones_summary
AS
select * from staged_tender_milestones_summary;

drop table if exists staged_tender_milestones_summary;

create unique index tender_milestones_summary_id on tender_milestones_summary(id, milestone_index);
create index tender_milestones_summary_data_id on tender_milestones_summary(data_id);
create index tender_milestones_summary_collection_id on tender_milestones_summary(collection_id);


----

drop table if exists staged_tender_items_summary;

create table staged_tender_items_summary
AS
select
    r.id,
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
        tps.*,
        value AS item,
        value -> 'unit' AS unit,
        ordinality -1 AS item_index 
    from 
        tmp_tender_summary tps 
    cross join
        jsonb_array_elements(tender -> 'items') with ordinality
    where jsonb_typeof(tender -> 'items') = 'array'
    ) AS r
;

----

drop table if exists tender_items_summary;

create table tender_items_summary
AS
select * from staged_tender_items_summary;

drop table if exists staged_tender_items_summary;

create unique index tender_items_summary_id on tender_items_summary(id, item_index);
create index tender_items_summary_data_id on tender_items_summary(data_id);
create index tender_items_summary_collection_id on tender_items_summary(collection_id);


----

drop table if exists staged_tender_summary;

create table staged_tender_summary
AS
select
    r.id,
    r.release_type,
    r.collection_id,
    r.ocid,
    r.release_id,
    r.data_id,
    tender ->> 'id' AS tender_id,
    tender ->> 'title' AS tender_title,
    tender ->> 'status' AS tender_status,
    convert_to_numeric(tender -> 'value' ->> 'amount') AS tender_value_amount,
    tender -> 'value' ->> 'currency' AS tender_value_currency,
    convert_to_numeric(tender -> 'minValue' ->> 'amount') AS tender_minValue_amount,
    tender -> 'minValue' ->> 'currency' AS tender_minValue_currency,
    tender ->> 'procurementMethod' AS tender_procurementMethod,
    tender ->> 'mainProcurementCategory' AS tender_mainProcurementCategory,
    tender -> 'additionalProcurementCategories' AS tender_additionalProcurementCategories,
    tender ->> 'awardCriteria' AS tender_awardCriteria,
    tender ->> 'submissionMethod' AS tender_submissionMethod,
    convert_to_timestamp(tender -> 'tenderPeriod' ->> 'startDate') AS tender_tenderPeriod_startDate,
    convert_to_timestamp(tender -> 'tenderPeriod' ->> 'endDate') AS tender_tenderPeriod_endDate,
    convert_to_timestamp(tender -> 'tenderPeriod' ->> 'maxExtentDate') AS tender_tenderPeriod_maxExtentDate,
    convert_to_numeric(tender -> 'tenderPeriod' ->> 'durationInDays') AS tender_tenderPeriod_durationInDays,
    convert_to_timestamp(tender -> 'enquiryPeriod' ->> 'startDate') AS tender_enquiryPeriod_startDate,
    convert_to_timestamp(tender -> 'enquiryPeriod' ->> 'endDate') AS tender_enquiryPeriod_endDate,
    convert_to_timestamp(tender -> 'enquiryPeriod' ->> 'maxExtentDate') AS tender_enquiryPeriod_maxExtentDate,
    convert_to_numeric(tender -> 'enquiryPeriod' ->> 'durationInDays') AS tender_enquiryPeriod_durationInDays,
    tender ->> 'hasEnquiries' AS tender_hasEnquiries,
    tender ->> 'eligibilityCriteria' AS tender_eligibilityCriteria,
    convert_to_timestamp(tender -> 'awardPeriod' ->> 'startDate') AS tender_awardPeriod_startDate,
    convert_to_timestamp(tender -> 'awardPeriod' ->> 'endDate') AS tender_awardPeriod_endDate,
    convert_to_timestamp(tender -> 'awardPeriod' ->> 'maxExtentDate') AS tender_awardPeriod_maxExtentDate,
    convert_to_numeric(tender -> 'awardPeriod' ->> 'durationInDays') AS tender_awardPeriod_durationInDays,
    convert_to_timestamp(tender -> 'contractPeriod' ->> 'startDate') AS tender_contractPeriod_startDate,
    convert_to_timestamp(tender -> 'contractPeriod' ->> 'endDate') AS tender_contractPeriod_endDate,
    convert_to_timestamp(tender -> 'contractPeriod' ->> 'maxExtentDate') AS tender_contractPeriod_maxExtentDate,
    convert_to_numeric(tender -> 'contractPeriod' ->> 'durationInDays') AS tender_contractPeriod_durationInDays,
    convert_to_numeric(tender ->> 'numberOfTenderers') AS tender_numberOfTenderers,
    jsonb_array_length(case when jsonb_typeof(tender->'tenderers') = 'array' then tender->'tenderers' else '[]'::jsonb end) as tenderers_count,
    documents_count,
    documentType_counts,
    milestones_count,
    milestoneType_counts,
    items_count
from
    tmp_tender_summary r
left join
    (
    select 
        id, 
        jsonb_object_agg(coalesce(documentType, ''), documentType_count) documentType_counts, 
        count(*) documents_count
    from
        (select 
            id, documentType, count(*) documentType_count
        from
            tender_documents_summary
        group by
            id, documentType
        ) AS d
    group by id
    ) documentType_counts
    using (id)
left join
    (
    select 
        id, 
        jsonb_object_agg(coalesce(type, ''), milestoneType_count) milestoneType_counts, 
        count(*) milestones_count
    from
        (select 
            id, type, count(*) milestoneType_count
        from
            tender_milestones_summary
        group by
            id, type
        ) AS d
    group by id
    ) milestoneType_counts
    using (id)
left join
    (
    select 
        id, 
        count(*) items_count
    from
        tender_items_summary
    group by id
    ) items_counts
    using (id)
;

----

drop table if exists tender_summary cascade;

create table tender_summary
AS
select * from staged_tender_summary;

drop table if exists staged_tender_summary;

create unique index tender_summary_id on tender_summary(id);
create index tender_summary_data_id on tender_summary(data_id);
create index tender_summary_collection_id on tender_summary(collection_id);


drop view if exists tender_summary_with_data;

create view tender_summary_with_data
AS
select 
    ts.*, 
    data -> 'tender' AS tender
from 
    tender_summary ts
join 
    data d on d.id = ts.data_id;


drop table if exists tmp_tender_summary;

