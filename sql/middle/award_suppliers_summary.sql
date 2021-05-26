CREATE TABLE award_suppliers_summary AS
WITH r AS (
    SELECT
        tas.*,
        value AS supplier,
        ORDINALITY - 1 AS supplier_index
    FROM
        tmp_awards_summary tas
        CROSS JOIN jsonb_array_elements(award -> 'suppliers') WITH ORDINALITY
    WHERE
        jsonb_typeof(award -> 'suppliers') = 'array'
)
SELECT DISTINCT ON ( r.id, award_index, supplier_index)
    r.id,
    award_index,
    supplier_index,
    r.release_type,
    r.collection_id,
    r.ocid,
    r.release_id,
    r.data_id,
    supplier,
    supplier ->> 'id' AS supplier_id,
    ps.identifier AS supplier_identifier,
    coalesce(supplier ->> 'id', hyphenate (supplier -> 'identifier' ->> 'scheme', supplier -> 'identifier' ->> 'id'), supplier ->> 'name'
) AS unique_identifier_attempt,
    ps.parties_additionalIdentifiers_ids AS supplier_additionalIdentifiers_ids,
    ps.total_parties_additionalIdentifiers AS total_supplier_additionalIdentifiers,
    CAST(ps.id IS NOT NULL AS integer
) AS link_to_parties,
    CAST(ps.id IS NOT NULL AND (ps.party -> 'roles') ? 'supplier' AS integer
) AS link_with_role,
    ps.party_index
FROM
    r
    LEFT JOIN parties_summary ps ON r.id = ps.id
        AND (supplier ->> 'id') = ps.parties_id
WHERE
    supplier IS NOT NULL;

CREATE UNIQUE INDEX award_suppliers_summary_id ON award_suppliers_summary (id, award_index, supplier_index);

CREATE INDEX award_suppliers_summary_data_id ON award_suppliers_summary (data_id);

CREATE INDEX award_suppliers_summary_collection_id ON award_suppliers_summary (collection_id);

