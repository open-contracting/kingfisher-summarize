DROP TABLE IF EXISTS tmp_contracts_summary;

CREATE TABLE tmp_contracts_summary AS
SELECT
    r.id,
    ORDINALITY - 1 AS contract_index,
    r.release_type,
    r.collection_id,
    r.ocid,
    r.release_id,
    r.data_id,
    value AS contract,
    value ->> 'awardID' AS award_id
FROM
    tmp_release_summary_with_release_data r
    CROSS JOIN jsonb_array_elements(data -> 'contracts')
    WITH ORDINALITY
WHERE
    jsonb_typeof(data -> 'contracts') = 'array';

CREATE UNIQUE INDEX tmp_contracts_summary_id ON tmp_contracts_summary (id, contract_index);

CREATE INDEX tmp_contracts_summary_award_id ON tmp_contracts_summary (id, award_id);

----
CREATE TABLE contract_items_summary AS
SELECT
    r.id,
    contract_index,
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
    tmp_contracts_summary r
    CROSS JOIN jsonb_array_elements(contract -> 'items')
    WITH ORDINALITY
WHERE
    jsonb_typeof(contract -> 'items') = 'array';

----
CREATE UNIQUE INDEX contract_items_summary_id ON contract_items_summary (id, contract_index, item_index);

CREATE INDEX contract_items_summary_data_id ON contract_items_summary (data_id);

CREATE INDEX contract_items_summary_collection_id ON contract_items_summary (collection_id);

----
CREATE TABLE contract_documents_summary AS
SELECT
    r.id,
    contract_index,
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
    tmp_contracts_summary r
    CROSS JOIN jsonb_array_elements(contract -> 'documents')
    WITH ORDINALITY
WHERE
    jsonb_typeof(contract -> 'documents') = 'array';

----
CREATE UNIQUE INDEX contract_documents_summary_id ON contract_documents_summary (id, contract_index, document_index);

CREATE INDEX contract_documents_summary_data_id ON contract_documents_summary (data_id);

CREATE INDEX contract_documents_summary_collection_id ON contract_documents_summary (collection_id);

----
CREATE TABLE contract_milestones_summary AS
SELECT
    r.id,
    contract_index,
    ORDINALITY - 1 AS milestone_index,
    r.release_type,
    r.collection_id,
    r.ocid,
    r.release_id,
    r.data_id,
    value AS milestone,
    value ->> 'type' AS TYPE,
    value ->> 'code' AS code,
    value ->> 'status' AS status
FROM
    tmp_contracts_summary r
    CROSS JOIN jsonb_array_elements(contract -> 'milestones')
    WITH ORDINALITY
WHERE
    jsonb_typeof(contract -> 'milestones') = 'array';

----
CREATE UNIQUE INDEX contract_milestones_summary_id ON contract_milestones_summary (id, contract_index, milestone_index);

CREATE INDEX contract_milestones_summary_data_id ON contract_milestones_summary (data_id);

CREATE INDEX contract_milestones_summary_collection_id ON contract_milestones_summary (collection_id);

----
CREATE TABLE contract_implementation_documents_summary AS
SELECT
    r.id,
    contract_index,
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
    tmp_contracts_summary r
    CROSS JOIN jsonb_array_elements(contract -> 'implementation' -> 'documents')
    WITH ORDINALITY
WHERE
    jsonb_typeof(contract -> 'implementation' -> 'documents') = 'array';

----
CREATE UNIQUE INDEX contract_implementation_documents_summary_id ON contract_implementation_documents_summary (id, contract_index, document_index);

CREATE INDEX contract_implementation_documents_summary_data_id ON contract_implementation_documents_summary (data_id);

CREATE INDEX contract_implementation_documents_summary_collection_id ON contract_implementation_documents_summary (collection_id);

----
CREATE TABLE contract_implementation_milestones_summary AS
SELECT
    r.id,
    contract_index,
    ORDINALITY - 1 AS milestone_index,
    r.release_type,
    r.collection_id,
    r.ocid,
    r.release_id,
    r.data_id,
    value AS milestone,
    value ->> 'type' AS TYPE,
    value ->> 'code' AS code,
    value ->> 'status' AS status
FROM
    tmp_contracts_summary r
    CROSS JOIN jsonb_array_elements(contract -> 'implementation' -> 'milestones')
    WITH ORDINALITY
WHERE
    jsonb_typeof(contract -> 'implementation' -> 'milestones') = 'array';

----
CREATE UNIQUE INDEX contract_implementation_milestones_summary_id ON contract_implementation_milestones_summary (id, contract_index, milestone_index);

CREATE INDEX contract_implementation_milestones_summary_data_id ON contract_implementation_milestones_summary (data_id);

CREATE INDEX contract_implementation_milestones_summary_collection_id ON contract_implementation_milestones_summary (collection_id);

----
CREATE TABLE contract_implementation_transactions_summary AS
SELECT
    r.id,
    contract_index,
    ORDINALITY - 1 AS transaction_index,
    r.release_type,
    r.collection_id,
    r.ocid,
    r.release_id,
    r.data_id,
    convert_to_numeric (coalesce(value -> 'value' ->> 'amount', value -> 'amount' ->> 'amount')) transaction_amount,
    coalesce(value -> 'value' ->> 'currency', value -> 'amount' ->> 'currency') transaction_currency
FROM
    tmp_contracts_summary r
    CROSS JOIN jsonb_array_elements(contract -> 'implementation' -> 'transactions')
    WITH ORDINALITY
WHERE
    jsonb_typeof(contract -> 'implementation' -> 'transactions') = 'array';

----
CREATE UNIQUE INDEX contract_implementation_transactions_summary_id ON contract_implementation_transactions_summary (id, contract_index, transaction_index);

CREATE INDEX contract_implementation_transactions_summary_data_id ON contract_implementation_transactions_summary (data_id);

CREATE INDEX contract_implementation_transactions_summary_collection_id ON contract_implementation_transactions_summary (collection_id);

----
CREATE TABLE contracts_summary_no_data AS SELECT DISTINCT ON (r.id, r.contract_index)
    r.id,
    r.contract_index,
    r.release_type,
    r.collection_id,
    r.ocid,
    r.release_id,
    r.data_id,
    r.award_id,
    CAST(aws.award_id IS NOT NULL AS integer) AS link_to_awards,
    contract ->> 'id' AS contract_id,
    contract ->> 'title' AS contract_title,
    contract ->> 'status' AS contract_status,
    contract ->> 'description' AS contract_description,
    convert_to_numeric (contract -> 'value' ->> 'amount') AS contract_value_amount,
    contract -> 'value' ->> 'currency' AS contract_value_currency,
    convert_to_timestamp (contract ->> 'dateSigned') AS dateSigned,
    convert_to_timestamp (contract -> 'period' ->> 'startDate') AS contract_period_startDate,
    convert_to_timestamp (contract -> 'period' ->> 'endDate') AS contract_period_endDate,
    convert_to_timestamp (contract -> 'period' ->> 'maxExtentDate') AS contract_period_maxExtentDate,
    convert_to_numeric (contract -> 'period' ->> 'durationInDays') AS contract_period_durationInDays,
    documentType_counts.documents_count,
    documentType_counts.documentType_counts,
    milestones_count,
    milestoneType_counts,
    items_counts.items_count,
    implementation_documents_count,
    implementation_documentType_counts,
    implementation_milestones_count,
    implementation_milestoneType_counts
FROM
    tmp_contracts_summary r
    LEFT JOIN awards_summary aws USING (id, award_id)
    LEFT JOIN (
        SELECT
            id,
            contract_index,
            jsonb_object_agg(coalesce(documentType, ''), documentType_count) documentType_counts,
            count(*) documents_count
        FROM (
            SELECT
                id,
                contract_index,
                documentType,
                count(*) documentType_count
            FROM
                contract_documents_summary
            GROUP BY
                id,
                contract_index,
                documentType) AS d
        GROUP BY
            id,
            contract_index) documentType_counts USING (id, contract_index)
    LEFT JOIN (
        SELECT
            id,
            contract_index,
            jsonb_object_agg(coalesce(documentType, ''), documentType_count) implementation_documentType_counts,
            count(*) implementation_documents_count
        FROM (
            SELECT
                id,
                contract_index,
                documentType,
                count(*) documentType_count
            FROM
                contract_implementation_documents_summary
            GROUP BY
                id,
                contract_index,
                documentType) AS d
        GROUP BY
            id,
            contract_index) implementation_documentType_counts USING (id, contract_index)
    LEFT JOIN (
        SELECT
            id,
            contract_index,
            count(*) items_count
        FROM
            contract_items_summary
        GROUP BY
            id,
            contract_index) items_counts USING (id, contract_index)
    LEFT JOIN (
        SELECT
            id,
            contract_index,
            jsonb_object_agg(coalesce(TYPE, ''), milestoneType_count) milestoneType_counts,
            count(*) milestones_count
        FROM (
            SELECT
                id,
                contract_index,
                TYPE,
                count(*) milestoneType_count
            FROM
                contract_milestones_summary
            GROUP BY
                id,
                contract_index,
                TYPE) AS d
        GROUP BY
            id,
            contract_index) milestoneType_counts USING (id, contract_index)
    LEFT JOIN (
        SELECT
            id,
            contract_index,
            jsonb_object_agg(coalesce(TYPE, ''), milestoneType_count) implementation_milestoneType_counts,
            count(*) implementation_milestones_count
        FROM (
            SELECT
                id,
                contract_index,
                TYPE,
                count(*) milestoneType_count
            FROM
                contract_implementation_milestones_summary
            GROUP BY
                id,
                contract_index,
                TYPE) AS d
        GROUP BY
            id,
            contract_index) implementation_milestoneType_counts USING (id, contract_index);

----
CREATE UNIQUE INDEX contracts_summary_no_data_id ON contracts_summary_no_data (id, contract_index);

CREATE INDEX contracts_summary_no_data_data_id ON contracts_summary_no_data (data_id);

CREATE INDEX contracts_summary_no_data_collection_id ON contracts_summary_no_data (collection_id);

CREATE INDEX contracts_summary_no_data_award_id ON contracts_summary_no_data (id, award_id);

CREATE VIEW contracts_summary AS
SELECT
    contracts_summary_no_data.*,
    data #> ARRAY['contracts', contract_index::text] AS contract
FROM
    contracts_summary_no_data
    JOIN data ON data.id = data_id;

DROP TABLE IF EXISTS tmp_contracts_summary;

-- The following pgpsql makes indexes on contracts_summary only if it is a table and not a view,
-- you will need to run --tables-only command line parameter to allow this to run.

DO $$
DECLARE
    query text;
BEGIN
    query := $query$ CREATE UNIQUE INDEX contracts_summary_id ON contracts_summary (id, contract_index);
    CREATE INDEX contracts_summary_data_id ON contracts_summary (data_id);
    CREATE INDEX contracts_summary_collection_id ON contracts_summary (collection_id);
    CREATE INDEX contracts_summary_award_id ON contracts_summary (id, award_id);
    $query$;
    EXECUTE query;
EXCEPTION
    WHEN wrong_object_type THEN
        NULL;
END;

$$;

