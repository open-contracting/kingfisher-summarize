DO $$
DECLARE
    milestones_query text;
BEGIN
    milestones_query := $milestones_query$
        CREATE TABLE %1$s AS
            SELECT
                r.id,
                %4$s
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
                %2$s r
            CROSS JOIN jsonb_array_elements(%3$s -> 'milestones')
            WITH ORDINALITY
            WHERE
                jsonb_typeof(%3$s -> 'milestones') = 'array';
        CREATE UNIQUE INDEX %1$s_id ON %1$s (id, %4$s milestone_index);
        CREATE INDEX %1$s_data_id ON %1$s (data_id);
        CREATE INDEX %1$s_collection_id ON %1$s (collection_id);
    $milestones_query$;

    -- format(milestones_query, create_table, from_table, jsonb_column_name, extra_select_line)
    -- %1$s create_table        The name of the table that will be CREATEd
    -- %2$s from_table          The name of the table to select from
    -- %3$s jsonb_column_name   The jsonb column to look for milestones within
    -- %4$s extra_select_line   An extra line to add to the SELECT clause
    EXECUTE format(milestones_query, 'tender_milestones_summary', 'tmp_tender_summary', 'tender', '');
    EXECUTE format(milestones_query, 'contract_milestones_summary', 'tmp_contracts_summary', 'contract', 'contract_index,');
END
$$;

