CREATE TABLE tmp_contracts_summary AS
SELECT
    r.id,
    ORDINALITY - 1 AS contract_index,
    r.release_type,
    r.collection_id,
    r.ocid,
    r.release_id,
    r.data_id,
    value AS contract,
    value ->> 'awardID' AS awardid
FROM
    tmp_release_summary_with_release_data r
    CROSS JOIN jsonb_array_elements(data -> 'contracts')
    WITH ORDINALITY
WHERE
    jsonb_typeof(data -> 'contracts') = 'array';

CREATE UNIQUE INDEX tmp_contracts_summary_id ON tmp_contracts_summary (id, contract_index);

CREATE INDEX tmp_contracts_summary_awardid ON tmp_contracts_summary (id, awardid);

