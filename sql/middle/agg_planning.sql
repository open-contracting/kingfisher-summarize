CREATE TABLE tmp_planning_documents_aggregates AS
SELECT
    id,
    jsonb_object_agg(coalesce(documenttype, ''), total_documenttypes) AS planning_document_documenttype_counts
FROM (
    SELECT
        id,
        documenttype,
        count(*) AS total_documenttypes
    FROM
        planning_documents_summary
    GROUP BY
        id,
        documenttype
) AS d
GROUP BY
    id;

CREATE UNIQUE INDEX tmp_planning_documents_aggregates_id ON tmp_planning_documents_aggregates (id);
