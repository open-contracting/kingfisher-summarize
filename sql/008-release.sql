DROP TABLE IF EXISTS tmp_release_party_aggregates;

CREATE TABLE tmp_release_party_aggregates AS
SELECT
    id,
    role_counts,
    total_roles,
    total_parties
FROM (
    SELECT
        id,
        count(*) total_parties
    FROM
        parties_summary
    GROUP BY
        id) parties_count
    LEFT JOIN (
        SELECT
            id,
            sum(role_count) AS total_roles,
            jsonb_object_agg(coalesce(ROLE, ''), role_count) role_counts
        FROM (
            SELECT
                id,
                ROLE,
                count(*) role_count
            FROM
                parties_summary
                CROSS JOIN jsonb_array_elements_text(roles) AS ROLE
            GROUP BY
                id,
                ROLE) id_role
        GROUP BY
            id) role_counts USING (id);

CREATE UNIQUE INDEX tmp_release_party_aggregates_id ON tmp_release_party_aggregates (id);

--- Adding planning document counts by document_type
DROP TABLE IF EXISTS tmp_planning_documents_aggregates;

CREATE TABLE tmp_planning_documents_aggregates AS
SELECT
    id,
    jsonb_object_agg(coalesce(documentType, ''), documentType_count) planning_documentType_counts
FROM (
    SELECT
        id,
        documentType,
        count(*) documentType_count
    FROM
        planning_documents_summary
    GROUP BY
        id,
        documentType) AS d
GROUP BY
    id;

CREATE UNIQUE INDEX tmp_planning_documents_aggregates_id ON tmp_planning_documents_aggregates (id);

-- end of adding planning document counts
--- Adding tender document counts by document_type
DROP TABLE IF EXISTS tmp_tender_documents_aggregates;

CREATE TABLE tmp_tender_documents_aggregates AS
SELECT
    id,
    jsonb_object_agg(coalesce(documentType, ''), documentType_count) tender_documentType_counts
FROM (
    SELECT
        id,
        documentType,
        count(*) documentType_count
    FROM
        tender_documents_summary
    GROUP BY
        id,
        documentType) AS d
GROUP BY
    id;

CREATE UNIQUE INDEX tmp_tender_documents_aggregates_id ON tmp_tender_documents_aggregates (id);

-- end of adding tender document counts
----
DROP TABLE IF EXISTS tmp_release_awards_aggregates;

CREATE TABLE tmp_release_awards_aggregates AS
SELECT
    id,
    count(*) AS award_count,
    min(award_date) AS first_award_date,
    max(award_date) AS last_award_date,
    sum(documents_count) AS total_award_documents,
    sum(items_count) AS total_award_items,
    sum(suppliers_count) AS total_award_suppliers,
    sum(award_value_amount) award_amount
FROM
    awards_summary
GROUP BY
    id;

CREATE UNIQUE INDEX tmp_release_awards_aggregates_id ON tmp_release_awards_aggregates (id);

DROP TABLE IF EXISTS tmp_release_award_suppliers_aggregates;

CREATE TABLE tmp_release_award_suppliers_aggregates AS
SELECT
    id,
    count(DISTINCT unique_identifier_attempt) AS unique_award_suppliers
FROM
    award_suppliers_summary
GROUP BY
    id;

CREATE UNIQUE INDEX tmp_release_award_suppliers_aggregates_id ON tmp_release_award_suppliers_aggregates (id);

DROP TABLE IF EXISTS tmp_award_documents_aggregates;

CREATE TABLE tmp_award_documents_aggregates AS
SELECT
    id,
    jsonb_object_agg(coalesce(documentType, ''), documentType_count) award_documentType_counts
FROM (
    SELECT
        id,
        documentType,
        count(*) documentType_count
    FROM
        award_documents_summary
    GROUP BY
        id,
        documentType) AS d
GROUP BY
    id;

CREATE UNIQUE INDEX tmp_award_documents_aggregates_id ON tmp_award_documents_aggregates (id);

DROP TABLE IF EXISTS tmp_release_contracts_aggregates;

CREATE TABLE tmp_release_contracts_aggregates AS
SELECT
    id,
    count(*) AS contract_count,
    sum(link_to_awards) total_contract_link_to_awards,
    sum(contract_value_amount) contract_amount,
    min(datesigned) AS first_contract_datesigned,
    max(datesigned) AS last_contract_datesigned,
    sum(documents_count) AS total_contract_documents,
    sum(milestones_count) AS total_contract_milestones,
    sum(items_count) AS total_contract_items,
    sum(implementation_documents_count) AS total_contract_implementation_documents,
    sum(implementation_milestones_count) AS total_contract_implementation_milestones
FROM
    contracts_summary
GROUP BY
    id;

CREATE UNIQUE INDEX tmp_release_contracts_aggregates_id ON tmp_release_contracts_aggregates (id);

DROP TABLE IF EXISTS tmp_contract_documents_aggregates;

CREATE TABLE tmp_contract_documents_aggregates AS
SELECT
    id,
    jsonb_object_agg(coalesce(documentType, ''), documentType_count) contract_documentType_counts
FROM (
    SELECT
        id,
        documentType,
        count(*) documentType_count
    FROM
        contract_documents_summary
    GROUP BY
        id,
        documentType) AS d
GROUP BY
    id;

CREATE UNIQUE INDEX tmp_contract_documents_aggregates_id ON tmp_contract_documents_aggregates (id);

DROP TABLE IF EXISTS tmp_contract_implementation_documents_aggregates;

CREATE TABLE tmp_contract_implementation_documents_aggregates AS
SELECT
    id,
    jsonb_object_agg(coalesce(documentType, ''), documentType_count) contract_implemetation_documentType_counts
FROM (
    SELECT
        id,
        documentType,
        count(*) documentType_count
    FROM
        contract_implementation_documents_summary
    GROUP BY
        id,
        documentType) AS d
GROUP BY
    id;

CREATE UNIQUE INDEX tmp_contract_implementation_documents_aggregates_id ON tmp_contract_implementation_documents_aggregates (id);

DROP TABLE IF EXISTS tmp_contract_milestones_aggregates;

CREATE TABLE tmp_contract_milestones_aggregates AS
SELECT
    id,
    jsonb_object_agg(coalesce(TYPE, ''), milestoneType_count) contract_milestoneType_counts
FROM (
    SELECT
        id,
        TYPE,
        count(*) milestoneType_count
    FROM
        contract_milestones_summary
    GROUP BY
        id,
        TYPE) AS d
GROUP BY
    id;

CREATE UNIQUE INDEX tmp_contract_milestones_aggregates_id ON tmp_contract_milestones_aggregates (id);

DROP TABLE IF EXISTS tmp_contract_implementation_milestones_aggregates;

CREATE TABLE tmp_contract_implementation_milestones_aggregates AS
SELECT
    id,
    jsonb_object_agg(coalesce(TYPE, ''), milestoneType_count) contract_implementation_milestoneType_counts
FROM (
    SELECT
        id,
        TYPE,
        count(*) milestoneType_count
    FROM
        contract_implementation_milestones_summary
    GROUP BY
        id,
        TYPE) AS d
GROUP BY
    id;

CREATE UNIQUE INDEX tmp_contract_implementation_milestones_aggregates_id ON tmp_contract_implementation_milestones_aggregates (id);

DROP TABLE IF EXISTS tmp_release_documents_aggregates;

CREATE TABLE tmp_release_documents_aggregates AS
WITH all_document_types AS (
    SELECT
        id,
        documentType
    FROM
        award_documents_summary
    UNION ALL
    SELECT
        id,
        documentType
    FROM
        contract_documents_summary
    UNION ALL
    SELECT
        id,
        documentType
    FROM
        contract_implementation_documents_summary
    UNION ALL
    SELECT
        id,
        documentType
    FROM
        planning_documents_summary
    UNION ALL
    SELECT
        id,
        documentType
    FROM
        tender_documents_summary
)
SELECT
    id,
    jsonb_object_agg (
coalesce(documentType, ''),
        documentType_count) total_documentType_counts,
    sum (
        documentType_count) total_documents
FROM (
    SELECT
        id,
        documentType,
        count(*) documentType_count
    FROM
        all_document_types
    GROUP BY
        id,
        documentType
) AS d
GROUP BY
    id;

CREATE UNIQUE INDEX tmp_release_documents_aggregates_id ON tmp_release_documents_aggregates (id);

DROP TABLE IF EXISTS tmp_release_milestones_aggregates;

CREATE TABLE tmp_release_milestones_aggregates AS
WITH all_milestone_types AS (
    SELECT
        id,
        TYPE
    FROM
        contract_milestones_summary
    UNION ALL
    SELECT
        id,
        TYPE
    FROM
        contract_implementation_milestones_summary
    UNION ALL
    SELECT
        id,
        TYPE
    FROM
        planning_milestones_summary
    UNION ALL
    SELECT
        id,
        TYPE
    FROM
        tender_milestones_summary
)
SELECT
    id,
    jsonb_object_agg (
coalesce(TYPE, ''),
        milestoneType_count) milestoneType_counts,
    sum (
        milestoneType_count) total_milestones
FROM (
    SELECT
        id,
        TYPE,
        count(*) milestoneType_count
    FROM
        all_milestone_types
    GROUP BY
        id,
        TYPE
) AS d
GROUP BY
    id;

CREATE UNIQUE INDEX tmp_release_milestones_aggregates_id ON tmp_release_milestones_aggregates (id);

----
DROP TABLE IF EXISTS staged_release_summary_no_data CASCADE;

CREATE TABLE staged_release_summary_no_data AS
SELECT
    *
FROM
    tmp_release_summary
    LEFT JOIN tmp_release_party_aggregates USING (id)
    LEFT JOIN (
        SELECT
            id,
            documents_count AS total_planning_documents
        FROM
            planning_summary) AS planning_summary USING (id)
    LEFT JOIN tmp_planning_documents_aggregates USING (id)
    LEFT JOIN (
        SELECT
            id,
            documents_count AS total_tender_documents
        FROM
            tender_summary) AS tender_summary USING (id)
    LEFT JOIN tmp_tender_documents_aggregates USING (id)
    LEFT JOIN tmp_release_awards_aggregates USING (id)
    LEFT JOIN tmp_release_award_suppliers_aggregates USING (id)
    LEFT JOIN tmp_award_documents_aggregates USING (id)
    LEFT JOIN tmp_release_contracts_aggregates USING (id)
    LEFT JOIN tmp_contract_documents_aggregates USING (id)
    LEFT JOIN tmp_contract_implementation_documents_aggregates USING (id)
    LEFT JOIN tmp_contract_milestones_aggregates USING (id)
    LEFT JOIN tmp_contract_implementation_milestones_aggregates USING (id)
    LEFT JOIN tmp_release_documents_aggregates USING (id)
    LEFT JOIN tmp_release_milestones_aggregates USING (id);

DROP TABLE IF EXISTS tmp_release_party_aggregates;

DROP TABLE IF EXISTS tmp_release_awards_aggregates;

DROP TABLE IF EXISTS tmp_release_award_suppliers_aggregates;

DROP TABLE IF EXISTS tmp_award_documents_aggregates;

DROP TABLE IF EXISTS tmp_tender_documents_aggregates;

DROP TABLE IF EXISTS tmp_planning_documents_aggregates;

DROP TABLE IF EXISTS tmp_release_contracts_aggregates;

DROP TABLE IF EXISTS tmp_contract_documents_aggregates;

DROP TABLE IF EXISTS tmp_contract_implementation_documents_aggregates;

DROP TABLE IF EXISTS tmp_contract_milestones_aggregates;

DROP TABLE IF EXISTS tmp_contract_implementation_milestones_aggregates;

DROP TABLE IF EXISTS tmp_release_documents_aggregates;

DROP TABLE IF EXISTS tmp_release_milestones_aggregates;

----
DROP TABLE IF EXISTS release_summary_no_data CASCADE;

CREATE TABLE release_summary_no_data AS
SELECT
    *
FROM
    staged_release_summary_no_data;

DROP TABLE IF EXISTS staged_release_summary_no_data;

CREATE UNIQUE INDEX release_summary_no_data_id ON release_summary_no_data (id);

CREATE INDEX release_summary_no_data_data_id ON release_summary_no_data (data_id);

CREATE INDEX release_summary_no_data_package_data_id ON release_summary_no_data (package_data_id);

CREATE INDEX release_summary_no_data_collection_id ON release_summary_no_data (collection_id);

DROP VIEW IF EXISTS release_summary;

CREATE VIEW release_summary AS
SELECT
    rs.*,
    c.source_id,
    c.data_version,
    c.store_start_at,
    c.store_end_at,
    c.sample,
    c.transform_type,
    c.transform_from_collection_id,
    c.deleted_at,
    CASE WHEN release_type = 'embedded_release' THEN
        d.data -> 'releases' -> (mod(rs.id / 10, 1000000)::integer)
    ELSE
        d.data
    END AS release,
    pd.data AS package_data,
    release_check.cove_output AS release_check,
    release_check11.cove_output AS release_check11,
    record_check.cove_output AS record_check,
    record_check11.cove_output AS record_check11
FROM
    release_summary_no_data rs
    JOIN data d ON d.id = rs.data_id
    JOIN collection c ON c.id = rs.collection_id
    LEFT JOIN release_check ON release_check.release_id = rs.table_id
        AND release_check.override_schema_version IS NULL
        AND release_type = 'release'
    LEFT JOIN release_check release_check11 ON release_check11.release_id = rs.table_id
        AND release_check11.override_schema_version = '1.1'
        AND release_type = 'release'
    LEFT JOIN record_check ON record_check.record_id = rs.table_id
        AND record_check.override_schema_version IS NULL
        AND release_type = 'record'
    LEFT JOIN record_check record_check11 ON record_check11.record_id = rs.table_id
        AND record_check11.override_schema_version = '1.1'
        AND release_type = 'record'
    --Kingfisher Process’ compiled_release table has no package_data_id column.
    --Therefore, any rows in release_summary_no_data sourced from that table will have a NULL package_data_id.
    LEFT JOIN package_data pd ON pd.id = rs.package_data_id;

-- The following pgpsql makes indexes on release_summary,
-- you will need to run --tables-only command line parameter to allow this to run.
DO $$
DECLARE
    query text;
BEGIN
    query := $query$ CREATE UNIQUE INDEX release_summary_id ON release_summary (id);
    CREATE INDEX release_summary_data_id ON release_summary (data_id);
    CREATE INDEX release_summary_package_data_id ON release_summary (package_data_id);
    CREATE INDEX release_summary_collection_id ON release_summary (collection_id);
    $query$;
    EXECUTE query;
    -- wrong_object_type is the specific exception when you try to add an index to a view.
EXCEPTION
    WHEN wrong_object_type THEN
        NULL;
END;

$$;

