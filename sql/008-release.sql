set search_path = views, public;

drop table if exists tmp_release_party_aggregates;

select
    id,
    role_counts,
    total_roles,
    total_parties

into tmp_release_party_aggregates

from
    (select id, count(*) total_parties from parties_summary group by id) parties_count
left join
    (select
        id, sum(role_count) as total_roles, jsonb_object_agg(role, role_count) role_counts
    from
        (select
            id, role, count(*) role_count
        from
            parties_summary
        cross join
            jsonb_array_elements_text(roles) as role
        group by id, role) id_role
    group by id) role_counts
using(id)
;

create unique index tmp_release_party_aggregates_id on tmp_release_party_aggregates(id);



drop table if exists tmp_release_awards_aggregates;

select
    id,
    count(*) as award_count,
    min(award_date) AS first_award_date,
    max(award_date) AS last_award_date,
    sum(documents_count) AS total_award_documents,
    sum(items_count) AS total_award_items,
    sum(suppliers_count) AS total_award_suppliers,
    sum(award_value_amount) award_amount
into 
    tmp_release_awards_aggregates
from
    awards_summary
group by id;

create unique index tmp_release_awards_aggregates_id on tmp_release_awards_aggregates(id);



drop table if exists tmp_release_award_suppliers_aggregates;

select 
    id, 
    count(distinct unique_identifier_attempt) AS unique_award_suppliers
into 
    tmp_release_award_suppliers_aggregates
from
    award_suppliers_summary
group by id
;

create unique index tmp_release_award_suppliers_aggregates_id on tmp_release_award_suppliers_aggregates(id);


drop table if exists tmp_release_award_suppliers_aggregates;

select 
    id, 
    count(distinct unique_identifier_attempt) AS unique_award_suppliers
into 
    tmp_release_award_suppliers_aggregates
from
    award_suppliers_summary
group by id
;

create unique index tmp_release_award_suppliers_aggregates_id on tmp_release_award_suppliers_aggregates(id);


drop table if exists tmp_award_documents_aggregates;
select 
    id, 
    jsonb_object_agg(documentType, documentType_count) award_documentType_counts
into tmp_award_documents_aggregates
from
    (select 
        id, documentType, count(*) documentType_count
    from
        award_documents_summary
    group by
        id, documentType
    ) AS d
group by id;

create unique index tmp_award_documents_aggregates_id on tmp_award_documents_aggregates(id);



drop table if exists tmp_release_contracts_aggregates;

select
    id,
    count(*) as contract_count,
    sum(link_to_awards) total_contract_link_to_awards,
    sum(contract_value_amount) contract_amount,
    min(datesigned) AS first_contract_datesigned,
    max(datesigned) AS last_contract_datesigned,
    sum(documents_count) AS total_contract_documents,
    sum(milestones_count) AS total_contract_milestones,
    sum(items_count) AS total_contract_items,
    sum(implementation_documents_count) AS total_contract_implementation_documents,
    sum(implementation_milestones_count) AS total_contract_implementation_milestones
into 
    tmp_release_contracts_aggregates
from
    contracts_summary
group by id;

create unique index tmp_release_contracts_aggregates_id on tmp_release_contracts_aggregates(id);



drop table if exists tmp_contract_documents_aggregates;
select 
    id, 
    jsonb_object_agg(documentType, documentType_count) contract_documentType_counts
into tmp_contract_documents_aggregates
from
    (select 
        id, documentType, count(*) documentType_count
    from
        contract_documents_summary
    group by
        id, documentType
    ) AS d
group by id;

create unique index tmp_contract_documents_aggregates_id on tmp_contract_documents_aggregates(id);


drop table if exists tmp_contract_implementation_documents_aggregates;
select 
    id, 
    jsonb_object_agg(documentType, documentType_count) contract_implemetation_documentType_counts
into tmp_contract_implementation_documents_aggregates
from
    (select 
        id, documentType, count(*) documentType_count
    from
        contract_implementation_documents_summary
    group by
        id, documentType
    ) AS d
group by id;

create unique index tmp_contract_implementation_documents_aggregates_id on tmp_contract_implementation_documents_aggregates(id);


drop table if exists tmp_contract_milestones_aggregates;
select 
    id, 
    jsonb_object_agg(type, milestoneType_count) contract_milestoneType_counts
into tmp_contract_milestones_aggregates
from
    (select 
        id, type, count(*) milestoneType_count
    from
        contract_milestones_summary
    group by
        id, type
    ) AS d
group by id;

create unique index tmp_contract_milestones_aggregates_id on tmp_contract_milestones_aggregates(id);


drop table if exists tmp_contract_implementation_milestones_aggregates;
select 
    id, 
    jsonb_object_agg(type, milestoneType_count) contract_implementation_milestoneType_counts
into tmp_contract_implementation_milestones_aggregates
from
    (select 
        id, type, count(*) milestoneType_count
    from
        contract_implementation_milestones_summary
    group by
        id, type
    ) AS d
group by id;

create unique index tmp_contract_implementation_milestones_aggregates_id on tmp_contract_implementation_milestones_aggregates(id);



drop table if exists tmp_release_documents_aggregates;

with all_document_types as (
    select id, documentType from award_documents_summary 
    union all
    select id, documentType from contract_documents_summary
    union all
    select id, documentType from contract_implementation_documents_summary
    union all
    select id, documentType from planning_documents_summary
    union all
    select id, documentType from tender_documents_summary
)
select 
    id, 
    jsonb_object_agg(coalesce(documentType, ''), documentType_count) total_documentType_counts,
    sum(documentType_count) total_documents
into tmp_release_documents_aggregates
from
    (select 
        id, documentType, count(*) documentType_count
    from
        all_document_types
    group by
        id, documentType
    ) AS d
group by id;


create unique index tmp_release_documents_aggregates_id on tmp_release_documents_aggregates(id);

drop table if exists tmp_release_milestones_aggregates;

with all_milestone_types as (
    select id, type from contract_milestones_summary
    union all
    select id, type from contract_implementation_milestones_summary
    union all
    select id, type from planning_milestones_summary
    union all
    select id, type from tender_milestones_summary
)
select 
    id, 
    jsonb_object_agg(coalesce(type, ''), milestoneType_count) milestoneType_counts,
    sum(milestoneType_count) total_milestones
into tmp_release_milestones_aggregates
from
    (select 
        id, type, count(*) milestoneType_count
    from
        all_milestone_types
    group by
        id, type
    ) AS d
group by id;

create unique index tmp_release_milestones_aggregates_id on tmp_release_milestones_aggregates(id);


drop table if exists release_summary;

select
    *
into release_summary
from
    tmp_release_summary
left join
    tmp_release_party_aggregates
using(id)
left join
    tmp_release_awards_aggregates
using(id)
left join
    tmp_release_award_suppliers_aggregates
using(id)
left join
    tmp_award_documents_aggregates
using(id)
left join
    tmp_release_contracts_aggregates
using(id)
left join
    tmp_contract_documents_aggregates
using(id)
left join
    tmp_contract_implementation_documents_aggregates
using(id)
left join
    tmp_contract_milestones_aggregates
using(id)
left join
    tmp_contract_implementation_milestones_aggregates
using(id)
left join
    tmp_release_documents_aggregates
using(id)
left join
    tmp_release_milestones_aggregates
using(id)
;


drop table if exists tmp_release_party_aggregates;
drop table if exists tmp_release_awards_aggregates;
drop table if exists tmp_release_award_suppliers_aggregates;
drop table if exists tmp_award_documents_aggregates;
drop table if exists tmp_release_contracts_aggregates;
drop table if exists tmp_contract_documents_aggregates;
drop table if exists tmp_contract_implementation_documents_aggregates;
drop table if exists tmp_contract_milestones_aggregates;
drop table if exists tmp_contract_implementation_milestones_aggregates;
drop table if exists tmp_release_documents_aggregates;
drop table if exists tmp_release_milestones_aggregates;

drop table if exists tmp_release_summary cascade;
