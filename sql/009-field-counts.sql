set search_path = views, public;

drop table if exists field_counts;

select 
    collection_id,
    path, 
    sum(object_property) object_property, 
    sum(array_item) array_count, 
    count(distinct release_summary.id) distinct_releases
into field_counts
from 
    release_summary 
join 
    data on data.id = data_id
cross join
    flatten(data)
group by collection_id, path;


drop table if exists field_counts_by_buyer;

select 
    release_summary.collection_id,
    path, 
    unique_identifier_attempt,
    buyer ->> 'name' as buyer_name,
    sum(object_property) object_property, 
    sum(array_item) array_count, 
    count(distinct release_summary.id) distinct_releases
into field_counts_by_buyer
from 
    release_summary 
join 
    data on data.id = data_id
join 
    buyer_summary on release_summary.id = buyer_summary.id
cross join
    flatten(data)
group by release_summary.collection_id, path, unique_identifier_attempt, buyer_name
