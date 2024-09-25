CREATE TABLE contract_implementation_milestones_summary AS
SELECT
    r.id,
    contract_index,
    ORDINALITY - 1 AS milestone_index,
    r.release_type,
    r.collection_id,
    r.ocid,
    r.release_id,
    r.data_id,
    value AS milestone,
    value ->> 'type' AS "type",
    value ->> 'code' AS code,
    value ->> 'status' AS status
FROM
    tmp_contracts_summary r
    CROSS JOIN jsonb_array_elements(contract -> 'implementation' -> 'milestones')
    WITH ORDINALITY
WHERE
    jsonb_typeof(contract -> 'implementation' -> 'milestones') = 'array';

CREATE UNIQUE INDEX contract_implementation_milestones_summary_id ON contract_implementation_milestones_summary (id, contract_index, milestone_index);

CREATE INDEX contract_implementation_milestones_summary_data_id ON contract_implementation_milestones_summary (data_id);

CREATE INDEX contract_implementation_milestones_summary_collection_id ON contract_implementation_milestones_summary (collection_id);

