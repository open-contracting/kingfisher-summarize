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
    convert_to_timestamp (d.data ->> 'date') date,
    d.data -> 'tag' tag,
    d.data ->> 'language' AS language
FROM
    release AS r
    JOIN package_data pd ON pd.id = r.package_data_id
    JOIN data d ON d.id = r.data_id
    JOIN collection c ON c.id = r.collection_id
WHERE
    collection_id IN (
        SELECT
            collection_id
        FROM
            summaries.selected_collections
        WHERE
            schema=current_schema())
        EXTRAWHERECLAUSE
UNION
SELECT
    r.id::bigint * 10 + 1 AS id,
    'record' AS release_type,
    r.id AS table_id,
    collection_id,
    ocid,
    d.data -> 'compiledRelease' ->> 'id' AS release_id,
    data_id,
    package_data_id,
    coalesce(pd.data ->> 'version', '1.0') AS package_version,
    convert_to_timestamp (d.data -> 'compiledRelease' ->> 'date') date,
    d.data -> 'compiledRelease' -> 'tag' tag,
    d.data -> 'compiledRelease' ->> 'language' AS language
FROM
    record AS r
    JOIN package_data pd ON pd.id = r.package_data_id
    JOIN data d ON d.id = r.data_id
    JOIN collection c ON c.id = r.collection_id
WHERE
    collection_id IN (
        SELECT
            collection_id
        FROM
            summaries.selected_collections
        WHERE
            schema=current_schema())
        EXTRAWHERECLAUSE
UNION
SELECT
    r.id::bigint * 10 + 2 AS id,
    'compiled_release' AS release_type,
    r.id AS table_id,
    collection_id,
    ocid,
    d.data ->> 'id' AS release_id,
    data_id,
    --Kingfisher Process’ compiled_release table has no package_data_id column, so setting package_data_id to null.
    NULL AS package_data_id,
    NULL AS package_version, -- this would be useful but hard to get
    convert_to_timestamp (d.data ->> 'date') date,
    d.data -> 'tag' tag,
    d.data ->> 'language' AS language
FROM
    compiled_release AS r
    JOIN data d ON d.id = r.data_id
WHERE
    collection_id IN (
        SELECT
            collection_id
        FROM
            summaries.selected_collections
        WHERE
            schema=current_schema())
        EXTRAWHERECLAUSE
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
    convert_to_timestamp (value ->> 'date') date,
    value -> 'tag' tag,
    value ->> 'language' AS language
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
            collection_id
        FROM
            summaries.selected_collections
        WHERE
            schema=current_schema())
        EXTRAWHERECLAUSE;

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

