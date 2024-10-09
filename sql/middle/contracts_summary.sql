CREATE TABLE contracts_summary_no_data AS SELECT DISTINCT ON (r.id, r.contract_index)
    r.id,
    r.contract_index,
    r.release_type,
    r.collection_id,
    r.ocid,
    r.release_id,
    r.data_id,
    r.awardid,
    (aws.awardid IS NOT NULL)::integer AS link_to_awards,
    contract ->> 'id' AS contract_id,
    contract ->> 'title' AS title,
    contract ->> 'status' AS status,
    contract ->> 'description' AS description,
    convert_to_numeric(contract -> 'value' ->> 'amount') AS value_amount,
    contract -> 'value' ->> 'currency' AS value_currency,
    convert_to_timestamp(contract ->> 'dateSigned') AS datesigned,
    convert_to_timestamp(contract -> 'period' ->> 'startDate') AS period_startdate,
    convert_to_timestamp(contract -> 'period' ->> 'endDate') AS period_enddate,
    convert_to_timestamp(contract -> 'period' ->> 'maxExtentDate') AS period_maxextentdate,
    convert_to_numeric(contract -> 'period' ->> 'durationInDays') AS period_durationindays,
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
    tmp_contracts_summary AS r
LEFT JOIN (SELECT
    award_id AS awardid,
    *
FROM awards_summary) AS aws USING (id, awardid)
LEFT JOIN (
    SELECT
        id,
        contract_index,
        count(*) AS total_items
    FROM
        contract_items_summary
    GROUP BY
        id,
        contract_index
) AS items_counts USING (id, contract_index)
LEFT JOIN (
    SELECT
        id,
        contract_index,
        count(*) AS total_implementation_transactions
    FROM
        contract_implementation_transactions_summary
    GROUP BY
        id,
        contract_index
) AS implementation_transactions_counts USING (id, contract_index)
LEFT JOIN (
    SELECT
        id,
        contract_index,
        jsonb_object_agg(coalesce(documenttype, ''), total_documenttypes) AS document_documenttype_counts,
        count(*) AS total_documents
    FROM (
        SELECT
            id,
            contract_index,
            documenttype,
            count(*) AS total_documenttypes
        FROM
            contract_documents_summary
        GROUP BY
            id,
            contract_index,
            documenttype
    ) AS d
    GROUP BY
        id,
        contract_index
) AS document_documenttype_counts USING (id, contract_index)
LEFT JOIN (
    SELECT
        id,
        contract_index,
        jsonb_object_agg(coalesce(documenttype, ''), total_documenttypes) AS implementation_document_documenttype_counts,
        count(*) AS total_implementation_documents
    FROM (
        SELECT
            id,
            contract_index,
            documenttype,
            count(*) AS total_documenttypes
        FROM
            contract_implementation_documents_summary
        GROUP BY
            id,
            contract_index,
            documenttype
    ) AS d
    GROUP BY
        id,
        contract_index
) AS implementation_document_documenttype_counts USING (id, contract_index)
LEFT JOIN (
    SELECT
        id,
        contract_index,
        jsonb_object_agg(coalesce(type, ''), total_milestonetypes) AS milestone_type_counts,
        count(*) AS total_milestones
    FROM (
        SELECT
            id,
            contract_index,
            type,
            count(*) AS total_milestonetypes
        FROM
            contract_milestones_summary
        GROUP BY
            id,
            contract_index,
            type
    ) AS d
    GROUP BY
        id,
        contract_index
) AS milestone_type_counts USING (id, contract_index)
LEFT JOIN (
    SELECT
        id,
        contract_index,
        jsonb_object_agg(coalesce(type, ''), total_milestonetypes) AS implementation_milestone_type_counts,
        count(*) AS total_implementation_milestones
    FROM (
        SELECT
            id,
            contract_index,
            type,
            count(*) AS total_milestonetypes
        FROM
            contract_implementation_milestones_summary
        GROUP BY
            id,
            contract_index,
            type
    ) AS d
    GROUP BY
        id,
        contract_index
) AS implementation_milestone_type_counts USING (id, contract_index);

CREATE UNIQUE INDEX contracts_summary_no_data_id ON contracts_summary_no_data (id, contract_index);

CREATE INDEX contracts_summary_no_data_data_id ON contracts_summary_no_data (data_id);

CREATE INDEX contracts_summary_no_data_collection_id ON contracts_summary_no_data (collection_id);

CREATE INDEX contracts_summary_no_data_awardid ON contracts_summary_no_data (id, awardid);

CREATE VIEW contracts_summary AS
SELECT
    s.*,
    CASE
        WHEN release_type = 'record'
            THEN
                d.data -> 'compiledRelease'
        WHEN release_type = 'embedded_release'
            THEN
                d.data -> 'releases' -> ((mod(s.id / 10, 1000000))::integer)
        ELSE
            d.data
    END -> 'contracts' -> contract_index::integer AS contract
FROM
    contracts_summary_no_data AS s
INNER JOIN data AS d ON s.data_id = d.id;

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
