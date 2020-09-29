DROP TABLE IF EXISTS tmp_tender_summary;

CREATE TABLE tmp_tender_summary AS
SELECT
    r.id,
    r.release_type,
    r.collection_id,
    r.ocid,
    r.release_id,
    r.data_id,
    tender
FROM (
    SELECT
        data -> 'tender' AS tender,
        rs.*
    FROM
        tmp_release_summary_with_release_data rs
    WHERE
        data ? 'tender') AS r;

CREATE UNIQUE INDEX tmp_tender_summary_id ON tmp_tender_summary (id);

----
DROP TABLE IF EXISTS staged_tender_documents_summary;

CREATE TABLE staged_tender_documents_summary AS
SELECT
    r.id,
    document_index,
    r.release_type,
    r.collection_id,
    r.ocid,
    r.release_id,
    r.data_id,
    document,
    document ->> 'documentType' AS documentType,
    document ->> 'format' AS format
FROM (
    SELECT
        tps.*,
        value AS document,
        ORDINALITY - 1 AS document_index
    FROM
        tmp_tender_summary tps
    CROSS JOIN jsonb_array_elements(tender -> 'documents')
    WITH ORDINALITY
WHERE
    jsonb_typeof(tender -> 'documents') = 'array') AS r;

----
DROP TABLE IF EXISTS tender_documents_summary;

CREATE TABLE tender_documents_summary AS
SELECT
    *
FROM
    staged_tender_documents_summary;

DROP TABLE IF EXISTS staged_tender_documents_summary;

CREATE UNIQUE INDEX tender_documents_summary_id ON tender_documents_summary (id, document_index);

CREATE INDEX tender_documents_summary_data_id ON tender_documents_summary (data_id);

CREATE INDEX tender_documents_summary_collection_id ON tender_documents_summary (collection_id);

----
DROP TABLE IF EXISTS staged_tender_milestones_summary;

CREATE TABLE staged_tender_milestones_summary AS
SELECT
    r.id,
    milestone_index,
    r.release_type,
    r.collection_id,
    r.ocid,
    r.release_id,
    r.data_id,
    milestone,
    milestone ->> 'type' AS TYPE,
    milestone ->> 'code' AS code,
    milestone ->> 'status' AS status
FROM (
    SELECT
        tps.*,
        value AS milestone,
        ORDINALITY - 1 AS milestone_index
    FROM
        tmp_tender_summary tps
    CROSS JOIN jsonb_array_elements(tender -> 'milestones')
    WITH ORDINALITY
WHERE
    jsonb_typeof(tender -> 'milestones') = 'array') AS r;

----
DROP TABLE IF EXISTS tender_milestones_summary;

CREATE TABLE tender_milestones_summary AS
SELECT
    *
FROM
    staged_tender_milestones_summary;

DROP TABLE IF EXISTS staged_tender_milestones_summary;

CREATE UNIQUE INDEX tender_milestones_summary_id ON tender_milestones_summary (id, milestone_index);

CREATE INDEX tender_milestones_summary_data_id ON tender_milestones_summary (data_id);

CREATE INDEX tender_milestones_summary_collection_id ON tender_milestones_summary (collection_id);

----
DROP TABLE IF EXISTS staged_tender_items_summary;

CREATE TABLE staged_tender_items_summary AS
SELECT
    r.id,
    item_index,
    r.release_type,
    r.collection_id,
    r.ocid,
    r.release_id,
    r.data_id,
    item,
    item ->> 'id' item_id,
    convert_to_numeric (item ->> 'quantity') quantity,
    convert_to_numeric (unit -> 'value' ->> 'amount') unit_amount,
    unit -> 'value' ->> 'currency' unit_currency,
    CASE WHEN item -> 'classification' ->> 'scheme' is null and item -> 'classification' ->> 'id' is null THEN
        null
    ELSE
        concat_ws('-', item -> 'classification' ->> 'scheme', item -> 'classification' ->> 'id')
    END AS item_classification,
    (
        SELECT
            jsonb_agg((additional_classification ->> 'scheme') || '-' || (additional_classification ->> 'id'))
        FROM
            jsonb_array_elements(
                CASE WHEN jsonb_typeof(item -> 'additionalClassifications') = 'array' THEN
                    item -> 'additionalClassifications'
                ELSE
                    '[]'::jsonb
                END) additional_classification
        WHERE
            additional_classification ?& ARRAY['scheme', 'id']) item_additionalIdentifiers_ids,
    jsonb_array_length(
        CASE WHEN jsonb_typeof(item -> 'additionalClassifications') = 'array' THEN
            item -> 'additionalClassifications'
        ELSE
            '[]'::jsonb
        END) AS additional_classification_count
FROM (
    SELECT
        tps.*,
        value AS item,
        value -> 'unit' AS unit,
        ORDINALITY - 1 AS item_index
    FROM
        tmp_tender_summary tps
    CROSS JOIN jsonb_array_elements(tender -> 'items')
    WITH ORDINALITY
WHERE
    jsonb_typeof(tender -> 'items') = 'array') AS r;

----
DROP TABLE IF EXISTS tender_items_summary;

CREATE TABLE tender_items_summary AS
SELECT
    *
FROM
    staged_tender_items_summary;

DROP TABLE IF EXISTS staged_tender_items_summary;

CREATE UNIQUE INDEX tender_items_summary_id ON tender_items_summary (id, item_index);

CREATE INDEX tender_items_summary_data_id ON tender_items_summary (data_id);

CREATE INDEX tender_items_summary_collection_id ON tender_items_summary (collection_id);

----
DROP TABLE IF EXISTS staged_tender_summary;

CREATE TABLE staged_tender_summary AS
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
    jsonb_array_length(
        CASE WHEN jsonb_typeof(tender -> 'tenderers') = 'array' THEN
            tender -> 'tenderers'
        ELSE
            '[]'::jsonb
        END) AS tenderers_count,
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

----
DROP TABLE IF EXISTS tender_summary CASCADE;

CREATE TABLE tender_summary AS
SELECT
    *
FROM
    staged_tender_summary;

DROP TABLE IF EXISTS staged_tender_summary;

CREATE UNIQUE INDEX tender_summary_id ON tender_summary (id);

CREATE INDEX tender_summary_data_id ON tender_summary (data_id);

CREATE INDEX tender_summary_collection_id ON tender_summary (collection_id);

DROP VIEW IF EXISTS tender_summary_with_data;

CREATE VIEW tender_summary_with_data AS
SELECT
    ts.*,
    data -> 'tender' AS tender
FROM
    tender_summary ts
    JOIN data d ON d.id = ts.data_id;

DROP TABLE IF EXISTS tmp_tender_summary;

