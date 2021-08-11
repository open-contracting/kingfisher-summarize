CREATE TABLE awards_summary_no_data AS
SELECT
    r.id,
    r.award_index,
    r.release_type,
    r.collection_id,
    r.ocid,
    r.release_id,
    r.data_id,
    award ->> 'id' AS award_id,
    award ->> 'title' AS title,
    award ->> 'status' AS status,
    award ->> 'description' AS description,
    convert_to_numeric (award -> 'value' ->> 'amount') AS value_amount,
    award -> 'value' ->> 'currency' AS value_currency,
    convert_to_timestamp (award ->> 'date') AS date,
    convert_to_timestamp (award -> 'contractPeriod' ->> 'startDate') AS contractPeriod_startDate,
    convert_to_timestamp (award -> 'contractPeriod' ->> 'endDate') AS contractPeriod_endDate,
    convert_to_timestamp (award -> 'contractPeriod' ->> 'maxExtentDate') AS contractPeriod_maxExtentDate,
    convert_to_numeric (award -> 'contractPeriod' ->> 'durationInDays') AS contractPeriod_durationInDays,
    CASE WHEN jsonb_typeof(award -> 'suppliers') = 'array' THEN
        jsonb_array_length(award -> 'suppliers')
    ELSE
        0
    END AS total_suppliers,
    total_documents,
    document_documenttype_counts,
    total_items
FROM
    tmp_awards_summary r
    LEFT JOIN (
        SELECT
            id,
            award_index,
            jsonb_object_agg(coalesce(documentType, ''), total_documentTypes) document_documenttype_counts,
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
            award_index) document_documenttype_counts USING (id, award_index)
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
    s.*,
    CASE WHEN release_type = 'record' THEN
        d.data -> 'compiledRelease'
    WHEN release_type = 'embedded_release' THEN
        d.data -> 'releases' -> (mod(s.id / 10, 1000000)::integer)
    ELSE
        d.data
    END -> 'awards' -> award_index::integer AS award
FROM
    awards_summary_no_data s
    JOIN data d ON d.id = s.data_id;

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

