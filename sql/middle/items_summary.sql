DO $$
DECLARE
    items_query text;
BEGIN
    items_query := $items_query$
        CREATE TABLE %1$s AS
            SELECT
                r.id,
                %4$s
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
                %2$s r
            CROSS JOIN jsonb_array_elements(%3$s -> 'items')
            WITH ORDINALITY
            WHERE
                jsonb_typeof(%3$s -> 'items') = 'array';
        CREATE UNIQUE INDEX %1$s_id ON %1$s (id, %4$s item_index);
        CREATE INDEX %1$s_data_id ON %1$s (data_id);
        CREATE INDEX %1$s_collection_id ON %1$s (collection_id);
    $items_query$;

    -- format(items_query, create_table, from_table, jsonb_column_name, extra_select_line)
    -- %1$s create_table        The name of the table that will be CREATEd
    -- %2$s from_table          The name of the table to select from
    -- %3$s jsonb_column_name   The jsonb column to look for items within
    -- %4$s extra_select_line   An extra line to add to the SELECT clause
    EXECUTE format(items_query, 'tender_items_summary', 'tmp_tender_summary', 'tender', '');
    EXECUTE format(items_query, 'contract_items_summary', 'tmp_contracts_summary', 'contract', 'contract_index,');
    EXECUTE format(items_query, 'award_items_summary', 'tmp_awards_summary', 'award', 'award_index,');
END
$$;

