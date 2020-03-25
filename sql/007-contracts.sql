
drop table if exists tmp_contracts_summary;

create table tmp_contracts_summary
AS
select
    r.id,
    contract_index,
    r.release_type,
    r.collection_id,
    r.ocid,
    r.release_id,
    r.data_id,
    contract,
    contract ->> 'awardID' as award_id
from
    (select 
        rs.*,
        ordinality - 1 AS contract_index,
        value as contract
    from 
        tmp_release_summary_with_release_data rs 
    cross join
        jsonb_array_elements(data -> 'contracts') with ordinality
    where jsonb_typeof(data -> 'contracts') = 'array'
    ) AS r
;

create unique index tmp_contracts_summary_id on tmp_contracts_summary(id, contract_index);
create index tmp_contracts_summary_award_id on tmp_contracts_summary(id, award_id);

----

drop table if exists staged_contract_items_summary;
create table staged_contract_items_summary
AS
select
    r.id,
    contract_index,
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
        tmp_contracts_summary tas 
    cross join
        jsonb_array_elements(contract -> 'items') with ordinality
    where jsonb_typeof(contract -> 'items') = 'array'
    ) AS r
;

----

drop table if exists contract_items_summary;

create table contract_items_summary
AS
select * from staged_contract_items_summary;

drop table if exists staged_contract_items_summary;

create unique index contract_items_summary_id on contract_items_summary(id, contract_index, item_index);
create index contract_items_summary_data_id on contract_items_summary(data_id);
create index contract_items_summary_collection_id on contract_items_summary(collection_id);

----

drop table if exists staged_contract_documents_summary;
create table staged_contract_documents_summary
AS
select
    r.id,
    contract_index,
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
        tmp_contracts_summary tas 
    cross join
        jsonb_array_elements(contract -> 'documents') with ordinality
    where jsonb_typeof(contract -> 'documents') = 'array'
    ) AS r
;

----

drop table if exists contract_documents_summary;

create table contract_documents_summary
AS
select * from staged_contract_documents_summary;

drop table if exists staged_contract_documents_summary;

create unique index contract_documents_summary_id on contract_documents_summary(id, contract_index, document_index);
create index contract_documents_summary_data_id on contract_documents_summary(data_id);
create index contract_documents_summary_collection_id on contract_documents_summary(collection_id);

----

drop table if exists staged_contract_milestones_summary;
create table staged_contract_milestones_summary
AS
select
    r.id,
    contract_index,
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
        tmp_contracts_summary tps 
    cross join
        jsonb_array_elements(contract -> 'milestones') with ordinality
    where jsonb_typeof(contract -> 'milestones') = 'array'
    ) AS r
;

----

drop table if exists contract_milestones_summary;

create table contract_milestones_summary
AS
select * from staged_contract_milestones_summary;

drop table if exists staged_contract_milestones_summary;

create unique index contract_milestones_summary_id on contract_milestones_summary(id, contract_index, milestone_index);
create index contract_milestones_summary_data_id on contract_milestones_summary(data_id);
create index contract_milestones_summary_collection_id on contract_milestones_summary(collection_id);

----

drop table if exists staged_contract_implementation_documents_summary;
create table staged_contract_implementation_documents_summary
AS
select
    r.id,
    contract_index,
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
        tmp_contracts_summary tas 
    cross join
        jsonb_array_elements(contract -> 'implementation' -> 'documents') with ordinality
    where jsonb_typeof(contract -> 'implementation' -> 'documents') = 'array'
    ) AS r
;

----

drop table if exists contract_implementation_documents_summary;

create table contract_implementation_documents_summary
AS
select * from staged_contract_implementation_documents_summary;

drop table if exists staged_contract_implementation_documents_summary;

create unique index contract_implementation_documents_summary_id on contract_implementation_documents_summary(id, contract_index, document_index);
create index contract_implementation_documents_summary_data_id on contract_implementation_documents_summary(data_id);
create index contract_implementation_documents_summary_collection_id on contract_implementation_documents_summary(collection_id);

----

drop table if exists staged_contract_implementation_milestones_summary;
create table staged_contract_implementation_milestones_summary
AS
select
    r.id,
    contract_index,
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
        tmp_contracts_summary tps 
    cross join
        jsonb_array_elements(contract -> 'implementation' -> 'milestones') with ordinality
    where jsonb_typeof(contract -> 'implementation' -> 'milestones') = 'array'
    ) AS r
;

----

drop table if exists contract_implementation_milestones_summary;

create table contract_implementation_milestones_summary
AS
select * from staged_contract_implementation_milestones_summary;

drop table if exists staged_contract_implementation_milestones_summary;

create unique index contract_implementation_milestones_summary_id on contract_implementation_milestones_summary(id, contract_index, milestone_index);
create index contract_implementation_milestones_summary_data_id on contract_implementation_milestones_summary(data_id);
create index contract_implementation_milestones_summary_collection_id on contract_implementation_milestones_summary(collection_id);

----

drop table if exists staged_contract_implementation_transactions_summary;

create table staged_contract_implementation_transactions_summary
AS
select
    r.id,
    contract_index,
    transaction_index,
    r.release_type,
    r.collection_id,
    r.ocid,
    r.release_id,
    r.data_id,
    convert_to_numeric(coalesce(transaction -> 'value' ->> 'amount', transaction -> 'amount' ->> 'amount')) transaction_amount,
    coalesce(transaction -> 'amount' ->> 'currency', transaction -> 'value' ->> 'currency') transaction_currency
from
    (select 
        tps.*,
        value AS transaction,
        ordinality -1 AS transaction_index 
    from 
        tmp_contracts_summary tps 
    cross join
        jsonb_array_elements(contract -> 'implementation' -> 'transactions') with ordinality
    where jsonb_typeof(contract -> 'implementation' -> 'transactions') = 'array'
    ) AS r
;

----

drop table if exists contract_implementation_transactions_summary;

create table contract_implementation_transactions_summary
AS
select * from staged_contract_implementation_transactions_summary;

drop table if exists staged_contract_implementation_transactions_summary;

create unique index contract_implementation_transactions_summary_id on contract_implementation_transactions_summary(id, contract_index, transaction_index);
create index contract_implementation_transactions_summary_data_id on contract_implementation_transactions_summary(data_id);
create index contract_implementation_transactions_summary_collection_id on contract_implementation_transactions_summary(collection_id);

----

drop table if exists staged_contracts_summary_no_data;
create table staged_contracts_summary_no_data
AS
select
    distinct on (r.id, r.contract_index)
    r.id,
    r.contract_index,
    r.release_type,
    r.collection_id,
    r.ocid,
    r.release_id,
    r.data_id,
    r.award_id,
    case when aws.award_id is not null then 1 else 0 end AS link_to_awards,
    contract ->> 'id' AS contract_id,
    contract ->> 'title' AS contract_title,
    contract ->> 'status' AS contract_status,
    convert_to_numeric(contract -> 'value' ->> 'amount') AS contract_value_amount,
    contract -> 'value' ->> 'currency' AS contract_value_currency,
    convert_to_timestamp(contract ->> 'dateSigned') AS dateSigned,
    convert_to_timestamp(contract -> 'period' ->> 'startDate') AS contract_period_startDate,
    convert_to_timestamp(contract -> 'period' ->> 'endDate') AS contract_period_endDate,
    convert_to_timestamp(contract -> 'period' ->> 'maxExtentDate') AS contract_period_maxExtentDate,
    convert_to_numeric(contract -> 'period' ->> 'durationInDays') AS contract_period_durationInDays,
    documentType_counts.documents_count,
    documentType_counts.documentType_counts,
    milestones_count,
    milestoneType_counts,
    items_counts.items_count,
    implementation_documents_count,
    implementation_documentType_counts,
    implementation_milestones_count,
    implementation_milestoneType_counts
from
    tmp_contracts_summary r
left join
    awards_summary aws using(id, award_id)
left join
    (
    select 
        id, 
        contract_index,
        jsonb_object_agg(coalesce(documentType, ''), documentType_count) documentType_counts, 
        count(*) documents_count
    from
        (select 
            id, contract_index, documentType, count(*) documentType_count
        from
            contract_documents_summary
        group by
            id, contract_index, documentType
        ) AS d
    group by id, contract_index
    ) documentType_counts
    using (id, contract_index)
left join
    (
    select 
        id, 
        contract_index,
        jsonb_object_agg(coalesce(documentType, ''), documentType_count) implementation_documentType_counts, 
        count(*) implementation_documents_count
    from
        (select 
            id, contract_index, documentType, count(*) documentType_count
        from
            contract_implementation_documents_summary
        group by
            id, contract_index, documentType
        ) AS d
    group by id, contract_index
    ) implementation_documentType_counts
    using (id, contract_index)
left join
    (
    select 
        id, 
        contract_index,
        count(*) items_count
    from
        contract_items_summary
    group by id, contract_index
    ) items_counts
    using (id, contract_index)
left join
    (
    select 
        id, 
        contract_index, 
        jsonb_object_agg(coalesce(type, ''), milestoneType_count) milestoneType_counts, 
        count(*) milestones_count
    from
        (select 
            id, contract_index, type, count(*) milestoneType_count
        from
            contract_milestones_summary
        group by
            id, contract_index, type
        ) AS d
    group by id, contract_index
    ) milestoneType_counts
    using (id, contract_index)
left join
    (
    select 
        id, 
        contract_index, 
        jsonb_object_agg(coalesce(type, ''), milestoneType_count) implementation_milestoneType_counts, 
        count(*) implementation_milestones_count
    from
        (select 
            id, contract_index, type, count(*) milestoneType_count
        from
            contract_implementation_milestones_summary
        group by
            id, contract_index, type
        ) AS d
    group by id, contract_index
    ) implementation_milestoneType_counts
    using (id, contract_index)
;

----

drop view if exists contracts_summary;

drop table if exists contracts_summary_no_data;

create table contracts_summary_no_data
AS
select * from staged_contracts_summary_no_data;

drop table if exists staged_contracts_summary_no_data;

create unique index contracts_summary_id on contracts_summary_no_data(id, contract_index);
create index contracts_summary_data_id on contracts_summary_no_data(data_id);
create index contracts_summary_collection_id on contracts_summary_no_data(collection_id);
create index contracts_summary_award_id on contracts_summary_no_data(id, award_id);


create view contracts_summary
AS
select 
    contracts_summary_no_data.*, 
    data #> ARRAY['contracts', contract_index::text] as contract
from 
    contracts_summary_no_data
join
    data on data.id = data_id;

drop table if exists tmp_contracts_summary;
