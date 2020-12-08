CREATE TABLE planning_summary_no_data AS
SELECT
    r.id,
    r.release_type,
    r.collection_id,
    r.ocid,
    r.release_id,
    r.data_id,
    convert_to_numeric (planning -> 'budget' -> 'amount' ->> 'amount') planning_budget_amount,
    planning -> 'budget' -> 'amount' ->> 'currency' planning_budget_currency,
    planning -> 'budget' ->> 'projectID' planning_budget_projectID,
    documents_count,
    documentType_counts,
    milestones_count,
    milestoneType_counts
FROM
    tmp_planning_summary r
    LEFT JOIN (
        SELECT
            id,
            jsonb_object_agg(coalesce(documentType, ''), documentType_count) documentType_counts,
            count(*) documents_count
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
            id) documentType_counts USING (id)
    LEFT JOIN (
        SELECT
            id,
            jsonb_object_agg(coalesce(TYPE, ''), milestoneType_count) milestoneType_counts,
            count(*) milestones_count
        FROM (
            SELECT
                id,
                TYPE,
                count(*) milestoneType_count
            FROM
                planning_milestones_summary
            GROUP BY
                id,
                TYPE) AS d
        GROUP BY
            id) milestoneType_counts USING (id);

CREATE UNIQUE INDEX planning_summary_no_data_id ON planning_summary_no_data (id);

CREATE INDEX planning_summary_no_data_data_id ON planning_summary_no_data (data_id);

CREATE INDEX planning_summary_no_data_collection_id ON planning_summary_no_data (collection_id);

CREATE VIEW planning_summary AS
SELECT
    planning_summary_no_data.*,
    data #> ARRAY['planning'] AS planning
FROM
    planning_summary_no_data
    JOIN data ON data.id = data_id;

-- The following pgpsql makes indexes on awards_summary only if it is a table and not a view,
-- you will need to run --tables-only command line parameter to allow this to run.

DO $$
DECLARE
    query text;
BEGIN
    query := $query$ CREATE UNIQUE INDEX planning_summary_id ON planning_summary (id);
    CREATE INDEX planning_summary_data_id ON planning_summary (data_id);
    CREATE INDEX planning_summary_collection_id ON planning_summary (collection_id);
    $query$;
    EXECUTE query;
EXCEPTION
    WHEN wrong_object_type THEN
        NULL;
END;

$$;
