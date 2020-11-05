CREATE TABLE tender_documents_summary AS
SELECT
    r.id,
    ORDINALITY - 1 AS document_index,
    r.release_type,
    r.collection_id,
    r.ocid,
    r.release_id,
    r.data_id,
    value AS document,
    value ->> 'documentType' AS documentType,
    value ->> 'format' AS format
FROM
    tmp_tender_summary r
    CROSS JOIN jsonb_array_elements(tender -> 'documents')
    WITH ORDINALITY
WHERE
    jsonb_typeof(tender -> 'documents') = 'array';

CREATE UNIQUE INDEX tender_documents_summary_id ON tender_documents_summary (id, document_index);

CREATE INDEX tender_documents_summary_data_id ON tender_documents_summary (data_id);

CREATE INDEX tender_documents_summary_collection_id ON tender_documents_summary (collection_id);

