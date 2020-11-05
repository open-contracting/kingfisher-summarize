CREATE TABLE award_documents_summary AS
SELECT
    r.id,
    award_index,
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
    tmp_awards_summary r
    CROSS JOIN jsonb_array_elements(award -> 'documents')
    WITH ORDINALITY
WHERE
    jsonb_typeof(award -> 'documents') = 'array';

CREATE UNIQUE INDEX award_documents_summary_id ON award_documents_summary (id, award_index, document_index);

CREATE INDEX award_documents_summary_data_id ON award_documents_summary (data_id);

CREATE INDEX award_documents_summary_collection_id ON award_documents_summary (collection_id);

