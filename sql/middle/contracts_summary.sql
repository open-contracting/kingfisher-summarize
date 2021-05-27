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
    contract ->> 'title' AS contract_title,
    contract ->> 'status' AS contract_status,
    contract ->> 'description' AS contract_description,
    convert_to_numeric (contract -> 'value' ->> 'amount') AS contract_value_amount,
    contract -> 'value' ->> 'currency' AS contract_value_currency,
    convert_to_timestamp (contract ->> 'dateSigned') AS dateSigned,
    convert_to_timestamp (contract -> 'period' ->> 'startDate') AS contract_period_startDate,
    convert_to_timestamp (contract -> 'period' ->> 'endDate') AS contract_period_endDate,
    convert_to_timestamp (contract -> 'period' ->> 'maxExtentDate') AS contract_period_maxExtentDate,
    convert_to_numeric (contract -> 'period' ->> 'durationInDays') AS contract_period_durationInDays,
    documentType_counts.total_documents,
    documentType_counts.documentType_counts,
    total_milestones,
    milestoneType_counts,
    items_counts.total_items,
    total_implementation_documents,
    implementation_documentType_counts,
    total_implementation_milestones,
    implementation_milestoneType_counts
FROM
    tmp_contracts_summary r
    LEFT JOIN awards_summary aws USING (id, awardid)
    LEFT JOIN (
        SELECT
            id,
            contract_index,
            jsonb_object_agg(coalesce(documentType, ''), total_documentTypes) documentType_counts,
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
            contract_index) documentType_counts USING (id, contract_index)
    LEFT JOIN (
        SELECT
            id,
            contract_index,
            jsonb_object_agg(coalesce(documentType, ''), total_documentTypes) implementation_documentType_counts,
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
            contract_index) implementation_documentType_counts USING (id, contract_index)
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
            jsonb_object_agg(coalesce(TYPE, ''), total_milestoneTypes) milestoneType_counts,
            count(*) total_milestones
        FROM (
            SELECT
                id,
                contract_index,
                TYPE,
                count(*) total_milestoneTypes
            FROM
                contract_milestones_summary
            GROUP BY
                id,
                contract_index,
                TYPE) AS d
        GROUP BY
            id,
            contract_index) milestoneType_counts USING (id, contract_index)
    LEFT JOIN (
        SELECT
            id,
            contract_index,
            jsonb_object_agg(coalesce(TYPE, ''), total_milestoneTypes) implementation_milestoneType_counts,
            count(*) total_implementation_milestones
        FROM (
            SELECT
                id,
                contract_index,
                TYPE,
                count(*) total_milestoneTypes
            FROM
                contract_implementation_milestones_summary
            GROUP BY
                id,
                contract_index,
                TYPE) AS d
        GROUP BY
            id,
            contract_index) implementation_milestoneType_counts USING (id, contract_index);

CREATE UNIQUE INDEX contracts_summary_no_data_id ON contracts_summary_no_data (id, contract_index);

CREATE INDEX contracts_summary_no_data_data_id ON contracts_summary_no_data (data_id);

CREATE INDEX contracts_summary_no_data_collection_id ON contracts_summary_no_data (collection_id);

CREATE INDEX contracts_summary_no_data_awardid ON contracts_summary_no_data (id, awardid);

CREATE VIEW contracts_summary AS
SELECT
    contracts_summary_no_data.*,
    data #> ARRAY['contracts', contract_index::text] AS contract
FROM
    contracts_summary_no_data
    JOIN data ON data.id = data_id;

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

