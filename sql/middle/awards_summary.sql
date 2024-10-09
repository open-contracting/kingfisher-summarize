CREATE TABLE awards_summary_no_data AS
WITH document_documenttype_counts AS (
    SELECT
        id,
        award_index,
        jsonb_object_agg(coalesce(documenttype, ''), total_documenttypes) AS document_documenttype_counts,
        count(*) AS total_documents
    FROM (
        SELECT
            id,
            award_index,
            documenttype,
            count(*) AS total_documenttypes
        FROM
            award_documents_summary
        GROUP BY
            id,
            award_index,
            documenttype
    ) AS d
    GROUP BY
        id,
        award_index
),

items_counts AS (
    SELECT
        id,
        award_index,
        count(*) AS total_items
    FROM
        award_items_summary
    GROUP BY
        id,
        award_index
)

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
    convert_to_numeric(award -> 'value' ->> 'amount') AS value_amount,
    award -> 'value' ->> 'currency' AS value_currency,
    convert_to_timestamp(award ->> 'date') AS date,
    convert_to_timestamp(award -> 'contractPeriod' ->> 'startDate') AS contractperiod_startdate,
    convert_to_timestamp(award -> 'contractPeriod' ->> 'endDate') AS contractperiod_enddate,
    convert_to_timestamp(award -> 'contractPeriod' ->> 'maxExtentDate') AS contractperiod_maxextentdate,
    convert_to_numeric(award -> 'contractPeriod' ->> 'durationInDays') AS contractperiod_durationindays,
    CASE
        WHEN jsonb_typeof(award -> 'suppliers') = 'array'
            THEN
                jsonb_array_length(award -> 'suppliers')
        ELSE
            0
    END AS total_suppliers,
    total_documents,
    document_documenttype_counts,
    total_items
FROM
    tmp_awards_summary AS r
LEFT JOIN document_documenttype_counts USING (id, award_index)
LEFT JOIN items_counts USING (id, award_index);

CREATE UNIQUE INDEX awards_summary_no_data_id ON awards_summary_no_data (id, award_index);

CREATE INDEX awards_summary_data_no_data_id ON awards_summary_no_data (data_id);

CREATE INDEX awards_summary_no_data_collection_id ON awards_summary_no_data (collection_id);

CREATE VIEW awards_summary AS
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
    END -> 'awards' -> award_index::integer AS award
FROM
    awards_summary_no_data AS s
INNER JOIN data AS d ON s.data_id = d.id;

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
