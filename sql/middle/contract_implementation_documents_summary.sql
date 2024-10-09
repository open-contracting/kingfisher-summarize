CREATE TABLE contract_implementation_documents_summary AS
SELECT
    r.id,
    contract_index,
    ordinality - 1 AS document_index,
    r.release_type,
    r.collection_id,
    r.ocid,
    r.release_id,
    r.data_id,
    value AS document,
    value ->> 'documentType' AS documenttype,
    value ->> 'format' AS format
FROM
    tmp_contracts_summary AS r
CROSS JOIN
    jsonb_array_elements(contract -> 'implementation' -> 'documents')
    WITH ORDINALITY
WHERE
    jsonb_typeof(contract -> 'implementation' -> 'documents') = 'array';

CREATE UNIQUE INDEX contract_implementation_documents_summary_id ON contract_implementation_documents_summary (id, contract_index, document_index);

CREATE INDEX contract_implementation_documents_summary_data_id ON contract_implementation_documents_summary (data_id);

CREATE INDEX contract_implementation_documents_summary_collection_id ON contract_implementation_documents_summary (collection_id);
