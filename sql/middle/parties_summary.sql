CREATE TABLE parties_summary_no_data AS
SELECT
    r.id,
    ORDINALITY - 1 AS party_index,
    release_type,
    collection_id,
    ocid,
    release_id,
    data_id,
    value ->> 'id' AS parties_id,
    value -> 'roles' AS roles,
    hyphenate(value -> 'identifier' ->> 'scheme', value -> 'identifier' ->> 'id') AS identifier,
    coalesce(value ->> 'id', hyphenate(value -> 'identifier' ->> 'scheme', value -> 'identifier' ->> 'id'), value ->> 'name') AS unique_identifier_attempt,
    (
        SELECT
            jsonb_agg(hyphenate(additional_identifier ->> 'scheme', additional_identifier ->> 'id'))
        FROM
            jsonb_array_elements(
                CASE WHEN jsonb_typeof(value -> 'additionalIdentifiers') = 'array' THEN
                    value -> 'additionalIdentifiers'
                ELSE
                    '[]'::jsonb
                END) additional_identifier
        WHERE
            additional_identifier ?& ARRAY['scheme', 'id']) parties_additionalIdentifiers_ids,
    CASE WHEN jsonb_typeof(value -> 'additionalIdentifiers') = 'array' THEN
        jsonb_array_length(value -> 'additionalIdentifiers')
    ELSE
        0
    END parties_additionalIdentifiers_count
FROM
    tmp_release_summary_with_release_data AS r
    CROSS JOIN jsonb_array_elements(data -> 'parties')
    WITH ORDINALITY
WHERE
    jsonb_typeof(data -> 'parties') = 'array';

CREATE UNIQUE INDEX parties_summary_no_data_id ON parties_summary_no_data (id, party_index);

CREATE INDEX parties_summary_no_data_data_id ON parties_summary_no_data (data_id);

CREATE INDEX parties_summary_no_data_collection_id ON parties_summary_no_data (collection_id);

CREATE INDEX parties_summary_no_data_party_id ON parties_summary_no_data (id, parties_id);

CREATE VIEW parties_summary AS
SELECT
    parties_summary_no_data.*,
    CASE WHEN release_type = 'record' THEN
        data #> ARRAY['compiledRelease', 'parties', party_index::text]
    WHEN release_type = 'embedded_release' THEN
        data -> 'releases' -> (mod(parties_summary_no_data.id / 10, 1000000)::integer) -> 'parties' -> party_index::integer
    ELSE
        data #> ARRAY['parties', party_index::text]
    END AS party
FROM
    parties_summary_no_data
    JOIN data ON data.id = data_id;

-- The following pgpsql makes indexes on parties_summary only if it is a table and not a view,
-- you will need to run --tables-only command line parameter to allow this to run.

DO $$
DECLARE
    query text;
BEGIN
    query := $query$ CREATE UNIQUE INDEX parties_summary_id ON parties_summary (id, party_index);
    CREATE INDEX parties_summary_data_id ON parties_summary (data_id);
    CREATE INDEX parties_summary_collection_id ON parties_summary (collection_id);
    CREATE INDEX parties_summary_party_id ON parties_summary (id, parties_id);
    $query$;
    EXECUTE query;
EXCEPTION
    WHEN wrong_object_type THEN
        NULL;
END;

$$;

