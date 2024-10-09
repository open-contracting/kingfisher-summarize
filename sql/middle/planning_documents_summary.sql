CREATE TABLE planning_documents_summary AS
SELECT
    r.id,
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
    tmp_planning_summary AS r
CROSS JOIN
    jsonb_array_elements(planning -> 'documents')
    WITH ORDINALITY
WHERE
    jsonb_typeof(planning -> 'documents') = 'array';

CREATE UNIQUE INDEX planning_documents_summary_id ON planning_documents_summary (id, document_index);

CREATE INDEX planning_documents_summary_data_id ON planning_documents_summary (data_id);

CREATE INDEX planning_documents_summary_collection_id ON planning_documents_summary (collection_id);
