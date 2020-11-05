CREATE TABLE tender_milestones_summary AS
SELECT
    r.id,
    ORDINALITY - 1 AS milestone_index,
    r.release_type,
    r.collection_id,
    r.ocid,
    r.release_id,
    r.data_id,
    value AS milestone,
    value ->> 'type' AS TYPE,
    value ->> 'code' AS code,
    value ->> 'status' AS status
FROM
    tmp_tender_summary r
    CROSS JOIN jsonb_array_elements(tender -> 'milestones')
    WITH ORDINALITY
WHERE
    jsonb_typeof(tender -> 'milestones') = 'array';

CREATE UNIQUE INDEX tender_milestones_summary_id ON tender_milestones_summary (id, milestone_index);

CREATE INDEX tender_milestones_summary_data_id ON tender_milestones_summary (data_id);

CREATE INDEX tender_milestones_summary_collection_id ON tender_milestones_summary (collection_id);

