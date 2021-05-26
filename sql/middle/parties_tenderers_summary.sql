CREATE TABLE tenderers_summary AS
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
    coalesce(tenderer ->> 'id', hyphenate(tenderer -> 'identifier' ->> 'scheme', tenderer -> 'identifier' ->> 'id'), tenderer ->> 'name'
) AS unique_identifier_attempt,
    ps.parties_additionalIdentifiers_ids AS tenderer_additionalIdentifiers_ids,
    ps.total_parties_additionalIdentifiers AS total_tenderer_additionalIdentifiers,
    CAST(ps.id IS NOT NULL AS integer
) AS link_to_parties,
    CAST(ps.id IS NOT NULL AND (ps.party -> 'roles') ? 'tenderer' AS integer
) AS link_with_role,
    ps.party_index
FROM
    r
    LEFT JOIN parties_summary ps ON r.id = ps.id
        AND (tenderer ->> 'id') = ps.parties_id
WHERE
    tenderer IS NOT NULL;

CREATE UNIQUE INDEX tenderers_summary_id ON tenderers_summary (id, tenderer_index);

CREATE INDEX tenderers_summary_data_id ON tenderers_summary (data_id);

CREATE INDEX tenderers_summary_collection_id ON tenderers_summary (collection_id);

