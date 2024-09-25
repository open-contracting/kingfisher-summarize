CREATE TABLE release_summary_no_data AS
SELECT
    *
FROM
    tmp_release_summary
    LEFT JOIN tmp_release_party_aggregates USING (id)
    LEFT JOIN (
        SELECT
            id,
            total_documents AS total_planning_documents,
            total_milestones AS total_planning_milestones
        FROM
            planning_summary) AS planning_summary USING (id)
    LEFT JOIN tmp_planning_documents_aggregates USING (id)
    LEFT JOIN (
        SELECT
            id,
            total_tenderers AS total_tender_tenderers,
            total_documents AS total_tender_documents,
            total_milestones AS total_tender_milestones,
            total_items AS total_tender_items
        FROM
            tender_summary) AS tender_summary USING (id)
    LEFT JOIN tmp_tender_documents_aggregates USING (id)
    LEFT JOIN tmp_awards_aggregates USING (id)
    LEFT JOIN tmp_award_suppliers_aggregates USING (id)
    LEFT JOIN tmp_award_documents_aggregates USING (id)
    LEFT JOIN tmp_contracts_aggregates USING (id)
    LEFT JOIN tmp_contract_documents_aggregates USING (id)
    LEFT JOIN tmp_contract_milestones_aggregates USING (id)
    LEFT JOIN tmp_contract_implementation_documents_aggregates USING (id)
    LEFT JOIN tmp_contract_implementation_milestones_aggregates USING (id)
    LEFT JOIN tmp_release_documents_aggregates USING (id)
    LEFT JOIN tmp_release_milestones_aggregates USING (id);

CREATE UNIQUE INDEX release_summary_no_data_id ON release_summary_no_data (id);

CREATE INDEX release_summary_no_data_data_id ON release_summary_no_data (data_id);

CREATE INDEX release_summary_no_data_package_data_id ON release_summary_no_data (package_data_id);

CREATE INDEX release_summary_no_data_collection_id ON release_summary_no_data (collection_id);

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
    CASE WHEN release_type = 'record' THEN
        d.data -> 'compiledRelease'
    WHEN release_type = 'embedded_release' THEN
        d.data -> 'releases' -> (mod(rs.id / 10, 1000000)::integer)
    ELSE
        d.data
    END AS release,
    pd.data AS package_data,
    release_check.cove_output AS release_check,
    record_check.cove_output AS record_check
FROM
    release_summary_no_data rs
    JOIN data d ON d.id = rs.data_id
    JOIN collection c ON c.id = rs.collection_id
    LEFT JOIN release_check ON release_check.release_id = rs.table_id
        AND release_type = 'release'
    LEFT JOIN record_check ON record_check.record_id = rs.table_id
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

