CREATE TABLE tmp_tender_documents_aggregates AS
SELECT
    id,
    jsonb_object_agg(coalesce(documentType, ''), total_documentTypes) tender_documentType_counts
FROM (
    SELECT
        id,
        documentType,
        count(*) total_documentTypes
    FROM
        tender_documents_summary
    GROUP BY
        id,
        documentType) AS d
GROUP BY
    id;

CREATE UNIQUE INDEX tmp_tender_documents_aggregates_id ON tmp_tender_documents_aggregates (id);

