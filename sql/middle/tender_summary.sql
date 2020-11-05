CREATE TABLE tender_summary_no_data AS
SELECT
    r.id,
    r.release_type,
    r.collection_id,
    r.ocid,
    r.release_id,
    r.data_id,
    tender ->> 'id' AS tender_id,
    tender ->> 'title' AS tender_title,
    tender ->> 'status' AS tender_status,
    tender ->> 'description' AS tender_description,
    convert_to_numeric (tender -> 'value' ->> 'amount') AS tender_value_amount,
    tender -> 'value' ->> 'currency' AS tender_value_currency,
    convert_to_numeric (tender -> 'minValue' ->> 'amount') AS tender_minValue_amount,
    tender -> 'minValue' ->> 'currency' AS tender_minValue_currency,
    tender ->> 'procurementMethod' AS tender_procurementMethod,
    tender ->> 'mainProcurementCategory' AS tender_mainProcurementCategory,
    tender -> 'additionalProcurementCategories' AS tender_additionalProcurementCategories,
    tender ->> 'awardCriteria' AS tender_awardCriteria,
    tender ->> 'submissionMethod' AS tender_submissionMethod,
    convert_to_timestamp (tender -> 'tenderPeriod' ->> 'startDate') AS tender_tenderPeriod_startDate,
    convert_to_timestamp (tender -> 'tenderPeriod' ->> 'endDate') AS tender_tenderPeriod_endDate,
    convert_to_timestamp (tender -> 'tenderPeriod' ->> 'maxExtentDate') AS tender_tenderPeriod_maxExtentDate,
    convert_to_numeric (tender -> 'tenderPeriod' ->> 'durationInDays') AS tender_tenderPeriod_durationInDays,
    convert_to_timestamp (tender -> 'enquiryPeriod' ->> 'startDate') AS tender_enquiryPeriod_startDate,
    convert_to_timestamp (tender -> 'enquiryPeriod' ->> 'endDate') AS tender_enquiryPeriod_endDate,
    convert_to_timestamp (tender -> 'enquiryPeriod' ->> 'maxExtentDate') AS tender_enquiryPeriod_maxExtentDate,
    convert_to_numeric (tender -> 'enquiryPeriod' ->> 'durationInDays') AS tender_enquiryPeriod_durationInDays,
    tender ->> 'hasEnquiries' AS tender_hasEnquiries,
    tender ->> 'eligibilityCriteria' AS tender_eligibilityCriteria,
    convert_to_timestamp (tender -> 'awardPeriod' ->> 'startDate') AS tender_awardPeriod_startDate,
    convert_to_timestamp (tender -> 'awardPeriod' ->> 'endDate') AS tender_awardPeriod_endDate,
    convert_to_timestamp (tender -> 'awardPeriod' ->> 'maxExtentDate') AS tender_awardPeriod_maxExtentDate,
    convert_to_numeric (tender -> 'awardPeriod' ->> 'durationInDays') AS tender_awardPeriod_durationInDays,
    convert_to_timestamp (tender -> 'contractPeriod' ->> 'startDate') AS tender_contractPeriod_startDate,
    convert_to_timestamp (tender -> 'contractPeriod' ->> 'endDate') AS tender_contractPeriod_endDate,
    convert_to_timestamp (tender -> 'contractPeriod' ->> 'maxExtentDate') AS tender_contractPeriod_maxExtentDate,
    convert_to_numeric (tender -> 'contractPeriod' ->> 'durationInDays') AS tender_contractPeriod_durationInDays,
    convert_to_numeric (tender ->> 'numberOfTenderers') AS tender_numberOfTenderers,
    CASE WHEN jsonb_typeof(tender -> 'tenderers') = 'array' THEN
        jsonb_array_length(tender -> 'tenderers')
    ELSE
        0
    END AS tenderers_count,
    documents_count,
    documentType_counts,
    milestones_count,
    milestoneType_counts,
    items_count
FROM
    tmp_tender_summary r
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
                tender_documents_summary
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
                tender_milestones_summary
            GROUP BY
                id,
                TYPE) AS d
        GROUP BY
            id) milestoneType_counts USING (id)
    LEFT JOIN (
        SELECT
            id,
            count(*) items_count
        FROM
            tender_items_summary
        GROUP BY
            id) items_counts USING (id);

CREATE UNIQUE INDEX tender_summary_no_data_id ON tender_summary_no_data (id);

CREATE INDEX tender_summary_no_data_data_id ON tender_summary_no_data (data_id);

CREATE INDEX tender_summary_no_data_collection_id ON tender_summary_no_data (collection_id);

CREATE VIEW tender_summary AS
SELECT
    tender_summary_no_data.*,
    data -> 'tender' AS tender
FROM
    tender_summary_no_data
    JOIN data d ON d.id = tender_summary_no_data.data_id;

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
