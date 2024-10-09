CREATE TABLE planning_summary_no_data AS
SELECT
    r.id,
    r.release_type,
    r.collection_id,
    r.ocid,
    r.release_id,
    r.data_id,
    convert_to_numeric(planning -> 'budget' -> 'amount' ->> 'amount') AS budget_amount_amount,
    planning -> 'budget' -> 'amount' ->> 'currency' AS budget_amount_currency,
    planning -> 'budget' ->> 'projectID' AS budget_projectid,
    total_documents,
    document_documenttype_counts,
    total_milestones,
    milestone_type_counts
FROM
    tmp_planning_summary AS r
LEFT JOIN (
    SELECT
        id,
        jsonb_object_agg(coalesce(documenttype, ''), total_documenttypes) AS document_documenttype_counts,
        count(*) AS total_documents
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
        id
) AS document_documenttype_counts USING (id)
LEFT JOIN (
    SELECT
        id,
        jsonb_object_agg(coalesce(type, ''), total_milestonetypes) AS milestone_type_counts,
        count(*) AS total_milestones
    FROM (
        SELECT
            id,
            type,
            count(*) AS total_milestonetypes
        FROM
            planning_milestones_summary
        GROUP BY
            id,
            type
    ) AS d
    GROUP BY
        id
) AS milestone_type_counts USING (id);

CREATE UNIQUE INDEX planning_summary_no_data_id ON planning_summary_no_data (id);

CREATE INDEX planning_summary_no_data_data_id ON planning_summary_no_data (data_id);

CREATE INDEX planning_summary_no_data_collection_id ON planning_summary_no_data (collection_id);

CREATE VIEW planning_summary AS
SELECT
    s.*,
    CASE
        WHEN release_type = 'record'
            THEN
                d.data -> 'compiledRelease'
        WHEN release_type = 'embedded_release'
            THEN
                d.data -> 'releases' -> (mod(s.id / 10, 1000000)::integer)
        ELSE
            d.data
    END -> 'planning' AS planning
FROM
    planning_summary_no_data AS s
INNER JOIN data AS d ON d.id = s.data_id;

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
