CREATE TABLE contracts_summary_no_data AS SELECT DISTINCT ON (r.id, r.contract_index)
    r.id,
    r.contract_index,
    r.release_type,
    r.collection_id,
    r.ocid,
    r.release_id,
    r.data_id,
    r.awardid,
    CAST(aws.awardid IS NOT NULL AS integer) AS link_to_awards,
    contract ->> 'id' AS contract_id,
    contract ->> 'title' AS title,
    contract ->> 'status' AS status,
    contract ->> 'description' AS description,
    convert_to_numeric (contract -> 'value' ->> 'amount') AS value_amount,
    contract -> 'value' ->> 'currency' AS value_currency,
    convert_to_timestamp (contract ->> 'dateSigned') AS dateSigned,
    convert_to_timestamp (contract -> 'period' ->> 'startDate') AS period_startDate,
    convert_to_timestamp (contract -> 'period' ->> 'endDate') AS period_endDate,
    convert_to_timestamp (contract -> 'period' ->> 'maxExtentDate') AS period_maxExtentDate,
    convert_to_numeric (contract -> 'period' ->> 'durationInDays') AS period_durationInDays,
    document_documenttype_counts.total_documents,
    document_documenttype_counts.document_documenttype_counts,
    total_milestones,
    milestone_type_counts,
    items_counts.total_items,
    total_implementation_documents,
    implementation_document_documenttype_counts,
    total_implementation_milestones,
    implementation_milestone_type_counts,
    total_implementation_transactions
FROM
    tmp_contracts_summary r
    LEFT JOIN (SELECT award_id AS awardid, * FROM awards_summary) aws USING (id, awardid)
    LEFT JOIN (
        SELECT
            id,
            contract_index,
            count(*) total_items
        FROM
            contract_items_summary
        GROUP BY
            id,
            contract_index) items_counts USING (id, contract_index)
    LEFT JOIN (
        SELECT
            id,
            contract_index,
            count(*) total_implementation_transactions
        FROM
            contract_implementation_transactions_summary
        GROUP BY
            id,
            contract_index) implementation_transactions_counts USING (id, contract_index)
    LEFT JOIN (
        SELECT
            id,
            contract_index,
            jsonb_object_agg(coalesce(documentType, ''), total_documentTypes) document_documenttype_counts,
            count(*) total_documents
        FROM (
            SELECT
                id,
                contract_index,
                documentType,
                count(*) total_documentTypes
            FROM
                contract_documents_summary
            GROUP BY
                id,
                contract_index,
                documentType) AS d
        GROUP BY
            id,
            contract_index) document_documenttype_counts USING (id, contract_index)
    LEFT JOIN (
        SELECT
            id,
            contract_index,
            jsonb_object_agg(coalesce(documentType, ''), total_documentTypes) implementation_document_documenttype_counts,
            count(*) total_implementation_documents
        FROM (
            SELECT
                id,
                contract_index,
                documentType,
                count(*) total_documentTypes
            FROM
                contract_implementation_documents_summary
            GROUP BY
                id,
                contract_index,
                documentType) AS d
        GROUP BY
            id,
            contract_index) implementation_document_documenttype_counts USING (id, contract_index)
    LEFT JOIN (
        SELECT
            id,
            contract_index,
            jsonb_object_agg(coalesce("type", ''), total_milestoneTypes) milestone_type_counts,
            count(*) total_milestones
        FROM (
            SELECT
                id,
                contract_index,
                "type",
                count(*) total_milestoneTypes
            FROM
                contract_milestones_summary
            GROUP BY
                id,
                contract_index,
                "type") AS d
        GROUP BY
            id,
            contract_index) milestone_type_counts USING (id, contract_index)
    LEFT JOIN (
        SELECT
            id,
            contract_index,
            jsonb_object_agg(coalesce("type", ''), total_milestoneTypes) implementation_milestone_type_counts,
            count(*) total_implementation_milestones
        FROM (
            SELECT
                id,
                contract_index,
                "type",
                count(*) total_milestoneTypes
            FROM
                contract_implementation_milestones_summary
            GROUP BY
                id,
                contract_index,
                "type") AS d
        GROUP BY
            id,
            contract_index) implementation_milestone_type_counts USING (id, contract_index);

CREATE UNIQUE INDEX contracts_summary_no_data_id ON contracts_summary_no_data (id, contract_index);

CREATE INDEX contracts_summary_no_data_data_id ON contracts_summary_no_data (data_id);

CREATE INDEX contracts_summary_no_data_collection_id ON contracts_summary_no_data (collection_id);

CREATE INDEX contracts_summary_no_data_awardid ON contracts_summary_no_data (id, awardid);

CREATE VIEW contracts_summary AS
SELECT
    s.*,
    CASE WHEN release_type = 'record' THEN
        d.data -> 'compiledRelease'
    WHEN release_type = 'embedded_release' THEN
        d.data -> 'releases' -> (mod(s.id / 10, 1000000)::integer)
    ELSE
        d.data
    END -> 'contracts' -> contract_index::integer AS contract
FROM
    contracts_summary_no_data s
    JOIN data d ON d.id = s.data_id;

-- The following pgpsql makes indexes on contracts_summary only if it is a table and not a view,
-- you will need to run --tables-only command line parameter to allow this to run.

DO $$
DECLARE
    query text;
BEGIN
    query := $query$ CREATE UNIQUE INDEX contracts_summary_id ON contracts_summary (id, contract_index);
    CREATE INDEX contracts_summary_data_id ON contracts_summary (data_id);
    CREATE INDEX contracts_summary_collection_id ON contracts_summary (collection_id);
    CREATE INDEX contracts_summary_awardid ON contracts_summary (id, awardid);
    $query$;
    EXECUTE query;
EXCEPTION
    WHEN wrong_object_type THEN
        NULL;
END;

$$;

