CREATE TABLE awards_summary_no_data AS
SELECT
    r.id,
    r.award_index,
    r.release_type,
    r.collection_id,
    r.ocid,
    r.release_id,
    r.data_id,
    award ->> 'id' AS awardid,
    award ->> 'title' AS award_title,
    award ->> 'status' AS award_status,
    award ->> 'description' AS award_description,
    convert_to_numeric (award -> 'value' ->> 'amount') AS award_value_amount,
    award -> 'value' ->> 'currency' AS award_value_currency,
    convert_to_timestamp (award ->> 'date') AS award_date,
    convert_to_timestamp (award -> 'contractPeriod' ->> 'startDate') AS award_contractPeriod_startDate,
    convert_to_timestamp (award -> 'contractPeriod' ->> 'endDate') AS award_contractPeriod_endDate,
    convert_to_timestamp (award -> 'contractPeriod' ->> 'maxExtentDate') AS award_contractPeriod_maxExtentDate,
    convert_to_numeric (award -> 'contractPeriod' ->> 'durationInDays') AS award_contractPeriod_durationInDays,
    CASE WHEN jsonb_typeof(award -> 'suppliers') = 'array' THEN
        jsonb_array_length(award -> 'suppliers')
    ELSE
        0
    END AS total_suppliers,
    total_documents,
    documentType_counts,
    total_items
FROM
    tmp_awards_summary r
    LEFT JOIN (
        SELECT
            id,
            award_index,
            jsonb_object_agg(coalesce(documentType, ''), total_documentTypes) documentType_counts,
            count(*) total_documents
        FROM (
            SELECT
                id,
                award_index,
                documentType,
                count(*) total_documentTypes
            FROM
                award_documents_summary
            GROUP BY
                id,
                award_index,
                documentType) AS d
        GROUP BY
            id,
            award_index) documentType_counts USING (id, award_index)
    LEFT JOIN (
        SELECT
            id,
            award_index,
            count(*) total_items
        FROM
            award_items_summary
        GROUP BY
            id,
            award_index) items_counts USING (id, award_index);

CREATE UNIQUE INDEX awards_summary_no_data_id ON awards_summary_no_data (id, award_index);

CREATE INDEX awards_summary_data_no_data_id ON awards_summary_no_data (data_id);

CREATE INDEX awards_summary_no_data_collection_id ON awards_summary_no_data (collection_id);

CREATE VIEW awards_summary AS
SELECT
    awards_summary_no_data.*,
    data #> ARRAY['awards', award_index::text] AS award
FROM
    awards_summary_no_data
    JOIN data ON data.id = data_id;

-- The following pgpsql makes indexes on awards_summary only if it is a table and not a view,
-- you will need to run --tables-only command line parameter to allow this to run.

DO $$
DECLARE
    query text;
BEGIN
    query := $query$ CREATE UNIQUE INDEX awards_summary_id ON awards_summary (id, award_index);
    CREATE INDEX awards_summary_data_id ON awards_summary (data_id);
    CREATE INDEX awards_summary_collection_id ON awards_summary (collection_id);
    $query$;
    EXECUTE query;
EXCEPTION
    WHEN wrong_object_type THEN
        NULL;
END;

$$;

