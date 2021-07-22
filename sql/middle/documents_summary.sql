DO $$
DECLARE
    documents_query text;
BEGIN
    documents_query := $documents_query$
        CREATE TABLE %1$s AS
            SELECT
                r.id,
                %4$s
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
                %2$s r
            CROSS JOIN jsonb_array_elements(%3$s -> 'documents')
            WITH ORDINALITY
            WHERE
                jsonb_typeof(%3$s -> 'documents') = 'array';
        CREATE UNIQUE INDEX %1$s_id ON %1$s (id, %4$s document_index);
        CREATE INDEX %1$s_data_id ON %1$s (data_id);
        CREATE INDEX %1$s_collection_id ON %1$s (collection_id);
    $documents_query$;

    -- format(documents_query, create_table, from_table, jsonb_column_name, extra_select_line)
    -- %1$s create_table        The name of the table that will be CREATEd
    -- %2$s from_table          The name of the table to select from
    -- %3$s jsonb_column_name   The jsonb column to look for documents within
    -- %4$s extra_select_line   An extra line to add to the SELECT clause
    EXECUTE format(documents_query, 'tender_documents_summary', 'tmp_tender_summary', 'tender', '');
    EXECUTE format(documents_query, 'contract_documents_summary', 'tmp_contracts_summary', 'contract', 'contract_index,');
    EXECUTE format(documents_query, 'award_documents_summary', 'tmp_awards_summary', 'award', 'award_index,');
END
$$;

