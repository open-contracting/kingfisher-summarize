CREATE TABLE tmp_awards_summary AS
SELECT
    r.id,
    ORDINALITY - 1 AS award_index,
    r.release_type,
    r.collection_id,
    r.ocid,
    r.release_id,
    r.data_id,
    value AS award
FROM
    tmp_release_summary_with_release_data r
    CROSS JOIN jsonb_array_elements(data -> 'awards')
    WITH ORDINALITY
WHERE
    jsonb_typeof(data -> 'awards') = 'array';

CREATE UNIQUE INDEX tmp_awards_summary_id ON tmp_awards_summary (id, award_index);

----
CREATE TABLE award_suppliers_summary AS SELECT DISTINCT ON (r.id, award_index, supplier_index)
    r.id,
    award_index,
    supplier_index,
    r.release_type,
    r.collection_id,
    r.ocid,
    r.release_id,
    r.data_id,
    supplier,
    supplier ->> 'id' AS supplier_parties_id,
    ps.identifier AS supplier_identifier,
    coalesce(supplier ->> 'id', (supplier -> 'identifier' ->> 'scheme') || '-' || (supplier -> 'identifier' ->> 'id'), supplier ->> 'name') AS unique_identifier_attempt,
    ps.parties_additionalIdentifiers_ids AS supplier_additionalIdentifiers_ids,
    ps.parties_additionalIdentifiers_count AS supplier_additionalIdentifiers_count,
    CAST(ps.id IS NOT NULL AS integer) AS link_to_parties,
    CAST(ps.id IS NOT NULL
        AND (ps.party -> 'roles') ? 'supplier' AS integer) AS link_with_role,
    ps.party_index
FROM (
    SELECT
        tas.*,
        value AS supplier,
        ORDINALITY - 1 AS supplier_index
    FROM
        tmp_awards_summary tas
    CROSS JOIN jsonb_array_elements(award -> 'suppliers')
    WITH ORDINALITY
WHERE
    jsonb_typeof(award -> 'suppliers') = 'array') AS r
    LEFT JOIN parties_summary ps ON r.id = ps.id
        AND (supplier ->> 'id') = ps.parties_id
WHERE
    supplier IS NOT NULL;

----
CREATE UNIQUE INDEX award_suppliers_summary_id ON award_suppliers_summary (id, award_index, supplier_index);

CREATE INDEX award_suppliers_summary_data_id ON award_suppliers_summary (data_id);

CREATE INDEX award_suppliers_summary_collection_id ON award_suppliers_summary (collection_id);

----
CREATE TABLE award_documents_summary AS
SELECT
    r.id,
    award_index,
    ORDINALITY - 1 AS document_index,
    r.release_type,
    r.collection_id,
    r.ocid,
    r.release_id,
    r.data_id,
    value AS document,
    value ->> 'documentType' AS documentType,
    value ->> 'format' AS format
FROM
    tmp_awards_summary r
    CROSS JOIN jsonb_array_elements(award -> 'documents')
    WITH ORDINALITY
WHERE
    jsonb_typeof(award -> 'documents') = 'array';

----
CREATE UNIQUE INDEX award_documents_summary_id ON award_documents_summary (id, award_index, document_index);

CREATE INDEX award_documents_summary_data_id ON award_documents_summary (data_id);

CREATE INDEX award_documents_summary_collection_id ON award_documents_summary (collection_id);

----
CREATE TABLE award_items_summary AS
SELECT
    r.id,
    award_index,
    ORDINALITY - 1 AS item_index,
    r.release_type,
    r.collection_id,
    r.ocid,
    r.release_id,
    r.data_id,
    value AS item,
    value ->> 'id' item_id,
    convert_to_numeric (value ->> 'quantity') quantity,
    convert_to_numeric (value -> 'unit' -> 'value' ->> 'amount') unit_amount,
    value -> 'unit' -> 'value' ->> 'currency' unit_currency,
    CASE WHEN value -> 'classification' ->> 'scheme' IS NULL
        AND value -> 'classification' ->> 'id' IS NULL THEN
        NULL
    ELSE
        concat_ws('-', value -> 'classification' ->> 'scheme', value -> 'classification' ->> 'id')
    END AS item_classification,
    (
        SELECT
            jsonb_agg((additional_classification ->> 'scheme') || '-' || (additional_classification ->> 'id'))
        FROM
            jsonb_array_elements(
                CASE WHEN jsonb_typeof(value -> 'additionalClassifications') = 'array' THEN
                    value -> 'additionalClassifications'
                ELSE
                    '[]'::jsonb
                END) additional_classification
        WHERE
            additional_classification ?& ARRAY['scheme', 'id']) item_additionalIdentifiers_ids,
    CASE WHEN jsonb_typeof(value -> 'additionalClassifications') = 'array' THEN
        jsonb_array_length(value -> 'additionalClassifications')
    ELSE
        0
    END AS additional_classification_count
FROM
    tmp_awards_summary r
    CROSS JOIN jsonb_array_elements(award -> 'items')
    WITH ORDINALITY
WHERE
    jsonb_typeof(award -> 'items') = 'array';

----
CREATE UNIQUE INDEX award_items_summary_id ON award_items_summary (id, award_index, item_index);

CREATE INDEX award_items_summary_data_id ON award_items_summary (data_id);

CREATE INDEX award_items_summary_collection_id ON award_items_summary (collection_id);

----
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
    END AS suppliers_count,
    documents_count,
    documentType_counts,
    items_count
FROM
    tmp_awards_summary r
    LEFT JOIN (
        SELECT
            id,
            award_index,
            jsonb_object_agg(coalesce(documentType, ''), documentType_count) documentType_counts,
            count(*) documents_count
        FROM (
            SELECT
                id,
                award_index,
                documentType,
                count(*) documentType_count
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
            count(*) items_count
        FROM
            award_items_summary
        GROUP BY
            id,
            award_index) items_counts USING (id, award_index);

----
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

DROP TABLE tmp_awards_summary;

