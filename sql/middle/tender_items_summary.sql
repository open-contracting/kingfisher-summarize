CREATE TABLE tender_items_summary AS
SELECT
    r.id,
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
    hyphenate(value -> 'classification' ->> 'scheme', value -> 'classification' ->> 'id') AS item_classification,
    (
        SELECT
            jsonb_agg(hyphenate(additional_classification ->> 'scheme', additional_classification ->> 'id'))
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
    END AS total_additional_classifications
FROM
    tmp_tender_summary r
    CROSS JOIN jsonb_array_elements(tender -> 'items')
    WITH ORDINALITY
WHERE
    jsonb_typeof(tender -> 'items') = 'array';

CREATE UNIQUE INDEX tender_items_summary_id ON tender_items_summary (id, item_index);

CREATE INDEX tender_items_summary_data_id ON tender_items_summary (data_id);

CREATE INDEX tender_items_summary_collection_id ON tender_items_summary (collection_id);

