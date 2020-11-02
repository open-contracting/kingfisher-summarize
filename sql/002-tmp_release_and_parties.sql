DROP VIEW IF EXISTS tmp_release_summary_with_release_data;

DROP TABLE IF EXISTS tmp_release_summary;

CREATE TABLE tmp_release_summary AS
SELECT
    r.id::bigint * 10 AS id,
    'release' AS release_type,
    r.id AS table_id,
    collection_id,
    ocid,
    release_id,
    data_id,
    package_data_id,
    coalesce(pd.data ->> 'version', '1.0') AS package_version,
    convert_to_timestamp (d.data ->> 'date') release_date,
    d.data -> 'tag' release_tag,
    d.data ->> 'language' release_language
FROM
    release AS r
    JOIN package_data pd ON pd.id = r.package_data_id
    JOIN data d ON d.id = r.data_id
    JOIN collection c ON c.id = r.collection_id
WHERE
    collection_id IN (
        SELECT
            id
        FROM
            selected_collections)
UNION
SELECT
    r.id::bigint * 10 + 1 AS id,
    'record' AS release_type,
    r.id AS table_id,
    collection_id,
    ocid,
    NULL AS release_id,
    data_id,
    package_data_id,
    coalesce(pd.data ->> 'version', '1.0') AS package_version,
    convert_to_timestamp (d.data -> 'compiledRelease' ->> 'date') release_date,
    d.data -> 'compiledRelease' -> 'tag' release_tag,
    d.data -> 'compiledRelease' ->> 'language' release_language
FROM
    record AS r
    JOIN package_data pd ON pd.id = r.package_data_id
    JOIN data d ON d.id = r.data_id
    JOIN collection c ON c.id = r.collection_id
WHERE
    collection_id IN (
        SELECT
            id
        FROM
            selected_collections)
UNION
SELECT
    r.id::bigint * 10 + 2 AS id,
    'compiled_release' AS release_type,
    r.id AS table_id,
    collection_id,
    ocid,
    NULL AS release_id,
    data_id,
    --Kingfisher Process’ compiled_release table has no package_data_id column, so setting package_data_id to null.
    NULL AS package_data_id,
    NULL AS package_version, -- this would be useful but hard to get
    convert_to_timestamp (d.data ->> 'date') release_date,
    d.data -> 'tag' release_tag,
    d.data ->> 'language' release_language
FROM
    compiled_release AS r
    JOIN data d ON d.id = r.data_id
WHERE
    collection_id IN (
        SELECT
            id
        FROM
            selected_collections)
UNION
SELECT
    (r.id::bigint * 1000000 + (ORDINALITY - 1)) * 10 + 3 AS id,
    'embedded_release' AS release_type,
    r.id AS table_id,
    collection_id,
    ocid,
    value ->> 'id' AS release_id,
    data_id,
    package_data_id,
    coalesce(pd.data ->> 'version', '1.0') AS package_version,
    convert_to_timestamp (value ->> 'date') release_date,
    value -> 'tag' release_tag,
    value ->> 'language' release_language
FROM
    record AS r
    JOIN package_data pd ON pd.id = r.package_data_id
    JOIN data d ON d.id = r.data_id
    JOIN collection c ON c.id = r.collection_id
    CROSS JOIN jsonb_array_elements(d.data -> 'releases')
    WITH ORDINALITY
WHERE
    -- We only want embedded releases, not linked releases
    (value -> 'id') IS NOT NULL
    AND collection_id IN (
        SELECT
            id
        FROM
            selected_collections);

CREATE UNIQUE INDEX tmp_release_summary_id ON tmp_release_summary (id);

CREATE INDEX tmp_release_summary_data_id ON tmp_release_summary (data_id);

CREATE INDEX tmp_release_summary_package_data_id ON tmp_release_summary (package_data_id);

CREATE INDEX tmp_release_summary_collection_id ON tmp_release_summary (collection_id);

CREATE VIEW tmp_release_summary_with_release_data AS
SELECT
    CASE WHEN release_type = 'record' THEN
        d.data -> 'compiledRelease'
    WHEN release_type = 'embedded_release' THEN
        d.data -> 'releases' -> (mod(r.id / 10, 1000000)::integer)
    ELSE
        d.data
    END AS data,
    r.*
FROM
    tmp_release_summary AS r
    JOIN data d ON d.id = r.data_id;

----
DROP VIEW IF EXISTS parties_summary;

DROP TABLE IF EXISTS parties_summary_no_data;

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
    CASE WHEN value -> 'identifier' ->> 'scheme' is null and value -> 'identifier' ->> 'id' is null THEN
        null
    ELSE
        concat_ws('-', value -> 'identifier' ->> 'scheme', value -> 'identifier' ->> 'id')
    END AS identifier,
    coalesce(value ->> 'id', (value -> 'identifier' ->> 'scheme') || '-' || (value -> 'identifier' ->> 'id'), value ->> 'name') AS unique_identifier_attempt,
    (
        SELECT
            jsonb_agg((additional_identifier ->> 'scheme') || '-' || (additional_identifier ->> 'id'))
        FROM
            jsonb_array_elements(
                CASE WHEN jsonb_typeof(value -> 'additionalIdentifiers') = 'array' THEN
                    value -> 'additionalIdentifiers'
                ELSE
                    '[]'::jsonb
                END) additional_identifier
        WHERE
            additional_identifier ?& ARRAY['scheme', 'id']) parties_additionalIdentifiers_ids,
    jsonb_array_length(
        CASE WHEN jsonb_typeof(value -> 'additionalIdentifiers') = 'array' THEN
            value -> 'additionalIdentifiers'
        ELSE
            '[]'::jsonb
        END) parties_additionalIdentifiers_count
FROM
    tmp_release_summary_with_release_data AS r
    CROSS JOIN jsonb_array_elements(data -> 'parties')
    WITH ORDINALITY
WHERE
    jsonb_typeof(data -> 'parties') = 'array';

----
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

