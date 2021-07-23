CREATE FUNCTION create_items (object_name text, group_name text, sql_fragment text)
RETURNS void
AS $$
DECLARE
    items_query text;
BEGIN
    items_query := $items_query$
        CREATE TABLE %1$s_items_summary AS
            SELECT
                r.id,
                %3$s
                ORDINALITY - 1 AS item_index,
                r.release_type,
                r.collection_id,
                r.ocid,
                r.release_id,
                r.data_id,
                value AS item,
                value ->> 'id' item_id,
                convert_to_numeric (value ->> 'quantity') quantity,
                convert_to_numeric (value -> 'unit' -> 'value' ->> 'amount') unit_value_amount,
                value -> 'unit' -> 'value' ->> 'currency' unit_value_currency,
                hyphenate (value -> 'classification' ->> 'scheme', value -> 'classification' ->> 'id') AS classification,
                (
                    SELECT
                        jsonb_agg(hyphenate (additionalclassification ->> 'scheme', additionalclassification ->> 'id'))
                    FROM
                        jsonb_array_elements(
                            CASE WHEN jsonb_typeof(value -> 'additionalClassifications') = 'array' THEN
                                value -> 'additionalClassifications'
                            ELSE
                                '[]'::jsonb
                            END) additionalclassification
                    WHERE
                        additionalclassification ?& ARRAY['scheme', 'id']) additionalclassifications_ids,
                CASE WHEN jsonb_typeof(value -> 'additionalClassifications') = 'array' THEN
                    jsonb_array_length(value -> 'additionalClassifications')
                ELSE
                    0
                END AS total_additionalclassifications
            FROM
                tmp_%2$s_summary r
            CROSS JOIN jsonb_array_elements(%1$s -> 'items')
            WITH ORDINALITY
            WHERE
                jsonb_typeof(%1$s -> 'items') = 'array';
        CREATE UNIQUE INDEX %1$s_items_summary_id ON %1$s_items_summary (id, %3$s item_index);
        CREATE INDEX %1$s_items_summary_data_id ON %1$s_items_summary (data_id);
        CREATE INDEX %1$s_items_summary_collection_id ON %1$s_items_summary (collection_id);
    $items_query$;

    EXECUTE format(items_query, object_name, group_name, sql_fragment);
END
$$
LANGUAGE plpgsql;


CREATE FUNCTION create_documents (object_name text, group_name text, sql_fragment text)
RETURNS void
AS $$
DECLARE
    documents_query text;
BEGIN
    documents_query := $documents_query$
        CREATE TABLE %1$s_documents_summary AS
            SELECT
                r.id,
                %3$s
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
                tmp_%2$s_summary r
            CROSS JOIN jsonb_array_elements(%1$s -> 'documents')
            WITH ORDINALITY
            WHERE
                jsonb_typeof(%1$s -> 'documents') = 'array';
        CREATE UNIQUE INDEX %1$s_documents_summary_id ON %1$s_documents_summary (id, %3$s document_index);
        CREATE INDEX %1$s_documents_summary_data_id ON %1$s_documents_summary (data_id);
        CREATE INDEX %1$s_documents_summary_collection_id ON %1$s_documents_summary (collection_id);
    $documents_query$;

    EXECUTE format(documents_query, object_name, group_name, sql_fragment);
END
$$
LANGUAGE plpgsql;


CREATE FUNCTION create_milestones (object_name text, group_name text, sql_fragment text)
RETURNS void
AS $$
DECLARE
    milestones_query text;
BEGIN
    milestones_query := $milestones_query$
        CREATE TABLE %1$s_milestones_summary AS
            SELECT
                r.id,
                %3$s
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
                tmp_%2$s_summary r
            CROSS JOIN jsonb_array_elements(%1$s -> 'milestones')
            WITH ORDINALITY
            WHERE
                jsonb_typeof(%1$s -> 'milestones') = 'array';
        CREATE UNIQUE INDEX %1$s_milestones_summary_id ON %1$s_milestones_summary (id, %3$s milestone_index);
        CREATE INDEX %1$s_milestones_summary_data_id ON %1$s_milestones_summary (data_id);
        CREATE INDEX %1$s_milestones_summary_collection_id ON %1$s_milestones_summary (collection_id);
    $milestones_query$;

    EXECUTE format(milestones_query, object_name, group_name, sql_fragment);
END
$$
LANGUAGE plpgsql;
