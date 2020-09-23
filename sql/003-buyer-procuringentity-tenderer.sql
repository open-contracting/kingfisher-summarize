DROP TABLE IF EXISTS staged_buyer_summary;

CREATE TABLE staged_buyer_summary AS
WITH r AS (
    SELECT
        *,
        data -> 'buyer' AS buyer
    FROM
        tmp_release_summary_with_release_data
)
SELECT DISTINCT ON ( r.id)
    r.id,
    r.release_type,
    r.collection_id,
    r.ocid,
    r.release_id,
    r.data_id,
    buyer,
    buyer ->> 'id' AS buyer_parties_id,
    buyer ->> 'name' AS buyer_name,
    ps.identifier AS buyer_identifier,
    coalesce(buyer ->> 'id', (buyer -> 'identifier' ->> 'scheme') || '-' || (buyer -> 'identifier' ->> 'id'), buyer ->> 'name'
) AS unique_identifier_attempt,
    ps.parties_additionalIdentifiers_ids AS buyer_additionalIdentifiers_ids,
    ps.parties_additionalIdentifiers_count AS buyer_additionalIdentifiers_count,
    CASE WHEN ps.id IS NOT NULL THEN
        1
    ELSE
        0
    END link_to_parties,
    CASE WHEN ps.id IS NOT NULL
        AND (ps.party -> 'roles') ? 'buyer' THEN
        1
    ELSE
        0
    END link_with_role,
    ps.party_index
FROM
    r
    LEFT JOIN parties_summary ps ON r.id = ps.id
        AND (buyer ->> 'id') = ps.parties_id
WHERE
    buyer IS NOT NULL;

----
DROP TABLE IF EXISTS buyer_summary;

CREATE TABLE buyer_summary AS
SELECT
    *
FROM
    staged_buyer_summary;

DROP TABLE IF EXISTS staged_buyer_summary;

CREATE UNIQUE INDEX buyer_summary_id ON buyer_summary (id);

CREATE INDEX buyer_summary_data_id ON buyer_summary (data_id);

CREATE INDEX buyer_summary_collection_id ON buyer_summary (collection_id);

----
DROP TABLE IF EXISTS staged_procuringEntity_summary;

CREATE TABLE staged_procuringEntity_summary AS
WITH r AS (
    SELECT
        *,
        data -> 'tender' -> 'procuringEntity' AS procuringEntity
    FROM
        tmp_release_summary_with_release_data
)
SELECT DISTINCT ON ( r.id)
    r.id,
    r.release_type,
    r.collection_id,
    r.ocid,
    r.release_id,
    r.data_id,
    procuringEntity,
    procuringEntity ->> 'id' AS procuringEntity_parties_id,
    ps.identifier AS procuringEntity_identifier,
    coalesce(procuringEntity ->> 'id', (procuringEntity -> 'identifier' ->> 'scheme') || '-' || (procuringEntity -> 'identifier' ->> 'id'), procuringEntity ->> 'name'
) AS unique_identifier_attempt,
    ps.parties_additionalIdentifiers_ids AS procuringEntity_additionalIdentifiers_ids,
    ps.parties_additionalIdentifiers_count AS procuringEntity_additionalIdentifiers_count,
    CASE WHEN ps.id IS NOT NULL THEN
        1
    ELSE
        0
    END link_to_parties,
    CASE WHEN ps.id IS NOT NULL
        AND (ps.party -> 'roles') ? 'procuringEntity' THEN
        1
    ELSE
        0
    END link_with_role,
    ps.party_index
FROM
    r
    LEFT JOIN parties_summary ps ON r.id = ps.id
        AND (procuringEntity ->> 'id') = ps.parties_id
WHERE
    procuringEntity IS NOT NULL;

----
DROP TABLE IF EXISTS procuringEntity_summary;

CREATE TABLE procuringEntity_summary AS
SELECT
    *
FROM
    staged_procuringEntity_summary;

DROP TABLE IF EXISTS staged_procuringEntity_summary;

CREATE UNIQUE INDEX procuringEntity_summary_id ON procuringEntity_summary (id);

CREATE INDEX procuringEntity_summary_data_id ON procuringEntity_summary (data_id);

CREATE INDEX procuringEntity_summary_collection_id ON procuringEntity_summary (collection_id);

----
DROP TABLE IF EXISTS staged_tenderers_summary;

CREATE TABLE staged_tenderers_summary AS
WITH r AS (
    SELECT
        rs.*,
        value AS tenderer,
        ORDINALITY - 1 AS tenderer_index
    FROM
        tmp_release_summary_with_release_data rs
        CROSS JOIN jsonb_array_elements(data -> 'tender' -> 'tenderers') WITH ORDINALITY
    WHERE
        jsonb_typeof(data -> 'tender' -> 'tenderers') = 'array'
)
SELECT DISTINCT ON ( r.id, tenderer_index)
    r.id,
    tenderer_index,
    r.release_type,
    r.collection_id,
    r.ocid,
    r.release_id,
    r.data_id,
    tenderer,
    tenderer ->> 'id' AS tenderer_parties_id,
    ps.identifier AS tenderer_identifier,
    coalesce(tenderer ->> 'id', (tenderer -> 'identifier' ->> 'scheme') || '-' || (tenderer -> 'identifier' ->> 'id'), tenderer ->> 'name'
) AS unique_identifier_attempt,
    ps.parties_additionalIdentifiers_ids AS tenderer_additionalIdentifiers_ids,
    ps.parties_additionalIdentifiers_count AS tenderer_additionalIdentifiers_count,
    CASE WHEN ps.id IS NOT NULL THEN
        1
    ELSE
        0
    END link_to_parties,
    CASE WHEN ps.id IS NOT NULL
        AND (ps.party -> 'roles') ? 'tenderer' THEN
        1
    ELSE
        0
    END link_with_role,
    ps.party_index
FROM
    r
    LEFT JOIN parties_summary ps ON r.id = ps.id
        AND (tenderer ->> 'id') = ps.parties_id
WHERE
    tenderer IS NOT NULL;

----
DROP TABLE IF EXISTS tenderers_summary;

CREATE TABLE tenderers_summary AS
SELECT
    *
FROM
    staged_tenderers_summary;

DROP TABLE IF EXISTS staged_tenderers_summary;

CREATE UNIQUE INDEX tenderers_summary_id ON tenderers_summary (id, tenderer_index);

CREATE INDEX tenderers_summary_data_id ON tenderers_summary (data_id);

CREATE INDEX tenderers_summary_collection_id ON tenderers_summary (collection_id);

