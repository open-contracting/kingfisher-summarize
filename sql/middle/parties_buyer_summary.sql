CREATE TABLE buyer_summary AS
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
    buyer ->> 'id' AS parties_id,
    buyer ->> 'name' AS name,
    ps.identifier AS identifier,
    coalesce(buyer ->> 'id', ps.unique_identifier_attempt, buyer ->> 'name') AS unique_identifier_attempt,
    ps.additionalIdentifiers_ids AS additionalIdentifiers_ids,
    ps.total_additionalIdentifiers AS total_additionalIdentifiers,
    CAST(ps.id IS NOT NULL AS integer
) AS link_to_parties,
    CAST(ps.id IS NOT NULL AND (ps.party -> 'roles') ? 'buyer' AS integer
) AS link_with_role,
    ps.party_index
FROM
    r
    LEFT JOIN parties_summary ps ON r.id = ps.id
        AND (buyer ->> 'id') = ps.parties_id
WHERE
    buyer IS NOT NULL;

CREATE UNIQUE INDEX buyer_summary_id ON buyer_summary (id);

CREATE INDEX buyer_summary_data_id ON buyer_summary (data_id);

CREATE INDEX buyer_summary_collection_id ON buyer_summary (collection_id);

