CREATE TABLE tmp_release_documents_aggregates AS
WITH all_document_types AS (
    SELECT
        id,
        documenttype
    FROM
        award_documents_summary
    UNION ALL
    SELECT
        id,
        documenttype
    FROM
        contract_documents_summary
    UNION ALL
    SELECT
        id,
        documenttype
    FROM
        contract_implementation_documents_summary
    UNION ALL
    SELECT
        id,
        documenttype
    FROM
        planning_documents_summary
    UNION ALL
    SELECT
        id,
        documenttype
    FROM
        tender_documents_summary
)

SELECT
    id,
    jsonb_object_agg(coalesce(documenttype, ''), total_documenttypes) AS document_documenttype_counts,
    sum(total_documenttypes) AS total_documents
FROM (
    SELECT
        id,
        documenttype,
        count(*) AS total_documenttypes
    FROM
        all_document_types
    GROUP BY
        id,
        documenttype
) AS d
GROUP BY
    id;

CREATE UNIQUE INDEX tmp_release_documents_aggregates_id ON tmp_release_documents_aggregates (id);
