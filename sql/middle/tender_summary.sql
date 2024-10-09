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
    convert_to_numeric(tender -> 'value' ->> 'amount') AS value_amount,
    tender -> 'value' ->> 'currency' AS value_currency,
    convert_to_numeric(tender -> 'minValue' ->> 'amount') AS minvalue_amount,
    tender -> 'minValue' ->> 'currency' AS minvalue_currency,
    tender ->> 'procurementMethod' AS procurementmethod,
    tender ->> 'mainProcurementCategory' AS mainprocurementcategory,
    tender -> 'additionalProcurementCategories' AS additionalprocurementcategories,
    tender ->> 'awardCriteria' AS awardcriteria,
    tender ->> 'submissionMethod' AS submissionmethod,
    convert_to_timestamp(tender -> 'tenderPeriod' ->> 'startDate') AS tenderperiod_startdate,
    convert_to_timestamp(tender -> 'tenderPeriod' ->> 'endDate') AS tenderperiod_enddate,
    convert_to_timestamp(tender -> 'tenderPeriod' ->> 'maxExtentDate') AS tenderperiod_maxextentdate,
    convert_to_numeric(tender -> 'tenderPeriod' ->> 'durationInDays') AS tenderperiod_durationindays,
    convert_to_timestamp(tender -> 'enquiryPeriod' ->> 'startDate') AS enquiryperiod_startdate,
    convert_to_timestamp(tender -> 'enquiryPeriod' ->> 'endDate') AS enquiryperiod_enddate,
    convert_to_timestamp(tender -> 'enquiryPeriod' ->> 'maxExtentDate') AS enquiryperiod_maxextentdate,
    convert_to_numeric(tender -> 'enquiryPeriod' ->> 'durationInDays') AS enquiryperiod_durationindays,
    tender ->> 'hasEnquiries' AS hasenquiries,
    tender ->> 'eligibilityCriteria' AS eligibilitycriteria,
    convert_to_timestamp(tender -> 'awardPeriod' ->> 'startDate') AS awardperiod_startdate,
    convert_to_timestamp(tender -> 'awardPeriod' ->> 'endDate') AS awardperiod_enddate,
    convert_to_timestamp(tender -> 'awardPeriod' ->> 'maxExtentDate') AS awardperiod_maxextentdate,
    convert_to_numeric(tender -> 'awardPeriod' ->> 'durationInDays') AS awardperiod_durationindays,
    convert_to_timestamp(tender -> 'contractPeriod' ->> 'startDate') AS contractperiod_startdate,
    convert_to_timestamp(tender -> 'contractPeriod' ->> 'endDate') AS contractperiod_enddate,
    convert_to_timestamp(tender -> 'contractPeriod' ->> 'maxExtentDate') AS contractperiod_maxextentdate,
    convert_to_numeric(tender -> 'contractPeriod' ->> 'durationInDays') AS contractperiod_durationindays,
    convert_to_numeric(tender ->> 'numberOfTenderers') AS numberoftenderers,
    CASE
        WHEN jsonb_typeof(tender -> 'tenderers') = 'array'
            THEN
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
    tmp_tender_summary AS r
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
            tender_documents_summary
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
            tender_milestones_summary
        GROUP BY
            id,
            type
    ) AS d
    GROUP BY
        id
) AS milestone_type_counts USING (id)
LEFT JOIN (
    SELECT
        id,
        count(*) AS total_items
    FROM
        tender_items_summary
    GROUP BY
        id
) AS items_counts USING (id);

CREATE UNIQUE INDEX tender_summary_no_data_id ON tender_summary_no_data (id);

CREATE INDEX tender_summary_no_data_data_id ON tender_summary_no_data (data_id);

CREATE INDEX tender_summary_no_data_collection_id ON tender_summary_no_data (collection_id);

CREATE VIEW tender_summary AS
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
    END -> 'tender' AS tender
FROM
    tender_summary_no_data AS s
INNER JOIN data AS d ON d.id = s.data_id;

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
