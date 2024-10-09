CREATE TABLE parties_summary_no_data AS
SELECT
    r.id,
    ordinality - 1 AS party_index,
    release_type,
    collection_id,
    ocid,
    release_id,
    data_id,
    value ->> 'id' AS party_id,
    value ->> 'name' AS name,
    CASE
        WHEN jsonb_typeof(value -> 'roles') = 'string'
            THEN
                to_jsonb(string_to_array(value ->> 'roles', ''))
        WHEN jsonb_typeof(value -> 'roles') = 'array'
            THEN
                value -> 'roles'
        ELSE
            '[]'::jsonb
    END AS roles,
    hyphenate(value -> 'identifier' ->> 'scheme', value -> 'identifier' ->> 'id') AS identifier,
    coalesce(value ->> 'id', hyphenate(value -> 'identifier' ->> 'scheme', value -> 'identifier' ->> 'id'), value ->> 'name') AS unique_identifier_attempt,
    (
        SELECT jsonb_agg(hyphenate(additional_identifier ->> 'scheme', additional_identifier ->> 'id'))
        FROM
            jsonb_array_elements(
                CASE
                    WHEN jsonb_typeof(value -> 'additionalIdentifiers') = 'array'
                        THEN
                            value -> 'additionalIdentifiers'
                    ELSE
                        '[]'::jsonb
                END
            -- https://github.com/sqlfluff/sqlfluff/issues/4623#issuecomment-2401209085
            ) AS additional_identifier -- noqa: AL05
        WHERE
            -- https://github.com/sqlfluff/sqlfluff/pull/6323
            additional_identifier ?& ARRAY['scheme', 'id'] -- noqa: LT02,PRS
    ) AS additionalidentifiers_ids,
    CASE
        WHEN jsonb_typeof(value -> 'additionalIdentifiers') = 'array'
            THEN
                jsonb_array_length(value -> 'additionalIdentifiers')
        ELSE
            0
    END AS total_additionalidentifiers
FROM
    tmp_release_summary_with_release_data AS r
CROSS JOIN
    jsonb_array_elements(data -> 'parties')
    WITH ORDINALITY
WHERE
    jsonb_typeof(data -> 'parties') = 'array';

CREATE UNIQUE INDEX parties_summary_no_data_id ON parties_summary_no_data (id, party_index);

CREATE INDEX parties_summary_no_data_data_id ON parties_summary_no_data (data_id);

CREATE INDEX parties_summary_no_data_collection_id ON parties_summary_no_data (collection_id);

CREATE INDEX parties_summary_no_data_party_id ON parties_summary_no_data (id, party_id);

-- Note: The `party` column is the last column, unlike in other tables.
CREATE VIEW parties_summary AS
SELECT
    s.*,
    CASE
        WHEN release_type = 'record'
            THEN
                d.data -> 'compiledRelease'
        WHEN release_type = 'embedded_release'
            THEN
                d.data -> 'releases' -> (mod(s.id / 10, 1000000)::integer)
        ELSE
            d.data
    END -> 'parties' -> party_index::integer AS party
FROM
    parties_summary_no_data AS s
INNER JOIN data AS d ON s.data_id = d.id;

-- The following pgpsql makes indexes on parties_summary only if it is a table and not a view,
-- you will need to run --tables-only command line parameter to allow this to run.

DO $$
DECLARE
    query text;
BEGIN
    query := $query$ CREATE UNIQUE INDEX parties_summary_id ON parties_summary (id, party_index);
    CREATE INDEX parties_summary_data_id ON parties_summary (data_id);
    CREATE INDEX parties_summary_collection_id ON parties_summary (collection_id);
    CREATE INDEX parties_summary_party_id ON parties_summary (id, party_id);
    $query$;
    EXECUTE query;
EXCEPTION
    WHEN wrong_object_type THEN
        NULL;
END;

$$;
