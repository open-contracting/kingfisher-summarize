CREATE TABLE tender_summary_no_data AS
SELECT
    r.id,
    r.release_type,
    r.collection_id,
    r.ocid,
    r.release_id,
    r.data_id,
    tender ->> 'id' AS tender_id,
    tender ->> 'title' AS title,
    tender ->> 'status' AS status,
    tender ->> 'description' AS description,
    convert_to_numeric (tender -> 'value' ->> 'amount') AS value_amount,
    tender -> 'value' ->> 'currency' AS value_currency,
    convert_to_numeric (tender -> 'minValue' ->> 'amount') AS minValue_amount,
    tender -> 'minValue' ->> 'currency' AS minValue_currency,
    tender ->> 'procurementMethod' AS procurementMethod,
    tender ->> 'mainProcurementCategory' AS mainProcurementCategory,
    tender -> 'additionalProcurementCategories' AS additionalProcurementCategories,
    tender ->> 'awardCriteria' AS awardCriteria,
    tender ->> 'submissionMethod' AS submissionMethod,
    convert_to_timestamp (tender -> 'tenderPeriod' ->> 'startDate') AS tenderPeriod_startDate,
    convert_to_timestamp (tender -> 'tenderPeriod' ->> 'endDate') AS tenderPeriod_endDate,
    convert_to_timestamp (tender -> 'tenderPeriod' ->> 'maxExtentDate') AS tenderPeriod_maxExtentDate,
    convert_to_numeric (tender -> 'tenderPeriod' ->> 'durationInDays') AS tenderPeriod_durationInDays,
    convert_to_timestamp (tender -> 'enquiryPeriod' ->> 'startDate') AS enquiryPeriod_startDate,
    convert_to_timestamp (tender -> 'enquiryPeriod' ->> 'endDate') AS enquiryPeriod_endDate,
    convert_to_timestamp (tender -> 'enquiryPeriod' ->> 'maxExtentDate') AS enquiryPeriod_maxExtentDate,
    convert_to_numeric (tender -> 'enquiryPeriod' ->> 'durationInDays') AS enquiryPeriod_durationInDays,
    tender ->> 'hasEnquiries' AS hasEnquiries,
    tender ->> 'eligibilityCriteria' AS eligibilityCriteria,
    convert_to_timestamp (tender -> 'awardPeriod' ->> 'startDate') AS awardPeriod_startDate,
    convert_to_timestamp (tender -> 'awardPeriod' ->> 'endDate') AS awardPeriod_endDate,
    convert_to_timestamp (tender -> 'awardPeriod' ->> 'maxExtentDate') AS awardPeriod_maxExtentDate,
    convert_to_numeric (tender -> 'awardPeriod' ->> 'durationInDays') AS awardPeriod_durationInDays,
    convert_to_timestamp (tender -> 'contractPeriod' ->> 'startDate') AS contractPeriod_startDate,
    convert_to_timestamp (tender -> 'contractPeriod' ->> 'endDate') AS contractPeriod_endDate,
    convert_to_timestamp (tender -> 'contractPeriod' ->> 'maxExtentDate') AS contractPeriod_maxExtentDate,
    convert_to_numeric (tender -> 'contractPeriod' ->> 'durationInDays') AS contractPeriod_durationInDays,
    convert_to_numeric (tender ->> 'numberOfTenderers') AS numberOfTenderers,
    CASE WHEN jsonb_typeof(tender -> 'tenderers') = 'array' THEN
        jsonb_array_length(tender -> 'tenderers')
    ELSE
        0
    END AS total_tenderers,
    total_documents,
    document_documenttype_counts,
    total_milestones,
    milestone_type_counts,
    total_items
FROM
    tmp_tender_summary r
    LEFT JOIN (
        SELECT
            id,
            jsonb_object_agg(coalesce(documentType, ''), total_documentTypes) document_documenttype_counts,
            count(*) total_documents
        FROM (
            SELECT
                id,
                documentType,
                count(*) total_documentTypes
            FROM
                tender_documents_summary
            GROUP BY
                id,
                documentType) AS d
        GROUP BY
            id) document_documenttype_counts USING (id)
    LEFT JOIN (
        SELECT
            id,
            jsonb_object_agg(coalesce("type", ''), total_milestoneTypes) milestone_type_counts,
            count(*) total_milestones
        FROM (
            SELECT
                id,
                "type",
                count(*) total_milestoneTypes
            FROM
                tender_milestones_summary
            GROUP BY
                id,
                "type") AS d
        GROUP BY
            id) milestone_type_counts USING (id)
    LEFT JOIN (
        SELECT
            id,
            count(*) total_items
        FROM
            tender_items_summary
        GROUP BY
            id) items_counts USING (id);

CREATE UNIQUE INDEX tender_summary_no_data_id ON tender_summary_no_data (id);

CREATE INDEX tender_summary_no_data_data_id ON tender_summary_no_data (data_id);

CREATE INDEX tender_summary_no_data_collection_id ON tender_summary_no_data (collection_id);

CREATE VIEW tender_summary AS
SELECT
    s.*,
    CASE WHEN release_type = 'record' THEN
        d.data -> 'compiledRelease'
    WHEN release_type = 'embedded_release' THEN
        d.data -> 'releases' -> (mod(s.id / 10, 1000000)::integer)
    ELSE
        d.data
    END -> 'tender' AS tender
FROM
    tender_summary_no_data s
    JOIN data d ON d.id = s.data_id;

-- The following pgpsql makes indexes on tender_summary only if it is a table and not a view,
-- you will need to run --tables-only command line parameter to allow this to run.

DO $$
DECLARE
    query text;
BEGIN
    query := $query$ CREATE UNIQUE INDEX tender_summary_id ON tender_summary (id);
    CREATE INDEX tender_summary_data_id ON tender_summary (data_id);
    CREATE INDEX tender_summary_collection_id ON tender_summary (collection_id);
    $query$;
    EXECUTE query;
EXCEPTION
    WHEN wrong_object_type THEN
        NULL;
END;

$$;
