CREATE FUNCTION create_items(object_name text, group_name text, sql_fragment text)
RETURNS void
AS $$
DECLARE
    query text;
BEGIN
    query := $query$
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
    $query$;

    EXECUTE format(query, object_name, group_name, sql_fragment);
END
$$
LANGUAGE plpgsql;


CREATE FUNCTION create_documents(object_name text, group_name text, sql_fragment text)
RETURNS void
AS $$
DECLARE
    query text;
BEGIN
    query := $query$
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
    $query$;

    EXECUTE format(query, object_name, group_name, sql_fragment);
END
$$
LANGUAGE plpgsql;


CREATE FUNCTION create_milestones(object_name text, group_name text, sql_fragment text)
RETURNS void
AS $$
DECLARE
    query text;
BEGIN
    query := $query$
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
                value ->> 'type' AS "type",
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
    $query$;

    EXECUTE format(query, object_name, group_name, sql_fragment);
END
$$
LANGUAGE plpgsql;


CREATE FUNCTION create_parties(object_name text, group_name text, sql_fragment text, sub_query text)
RETURNS void
AS $$
DECLARE
    query text;
BEGIN
    query := $query$
        CREATE TABLE %2$s_summary AS
        WITH r AS (%4$s)
        SELECT DISTINCT ON (%3$s r.id)
            r.id,
            %3$s
            r.release_type,
            r.collection_id,
            r.ocid,
            r.release_id,
            r.data_id,
            %1$s,
            %1$s ->> 'id' AS %1$s_id,
            %1$s ->> 'name' AS name,
            ps.identifier AS identifier,
            coalesce(%1$s ->> 'id', ps.unique_identifier_attempt, %1$s ->> 'name') AS unique_identifier_attempt,
            ps.additionalIdentifiers_ids AS additionalIdentifiers_ids,
            ps.total_additionalIdentifiers AS total_additionalIdentifiers,
            CAST(ps.id IS NOT NULL AS integer
        ) AS link_to_parties,
            CAST(ps.id IS NOT NULL AND (ps.party -> 'roles') ? '%1$s' AS integer
        ) AS link_with_role,
            ps.party_index
        FROM
            r
            LEFT JOIN parties_summary ps ON r.id = ps.id
                AND (%1$s ->> 'id') = ps.party_id
        WHERE
            %1$s IS NOT NULL;

        CREATE UNIQUE INDEX %2$s_summary_id ON %2$s_summary (%3$s id);
        CREATE INDEX %2$s_summary_data_id ON %2$s_summary (data_id);
        CREATE INDEX %2$s_summary_collection_id ON %2$s_summary (collection_id);
    $query$;

    EXECUTE format(query, object_name, group_name, sql_fragment, sub_query);
END
$$
LANGUAGE plpgsql;
