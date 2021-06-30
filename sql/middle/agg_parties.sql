CREATE TABLE tmp_release_party_aggregates AS
SELECT
    id,
    parties_role_counts,
    total_parties_roles,
    total_parties
FROM (
    SELECT
        id,
        count(*) total_parties
    FROM
        parties_summary
    GROUP BY
        id) total_parties
    LEFT JOIN (
        SELECT
            id,
            sum(total_parties_roles) AS total_parties_roles,
            jsonb_object_agg(coalesce(ROLE, ''), total_parties_roles) parties_role_counts
        FROM (
            SELECT
                id,
                ROLE,
                count(*) total_parties_roles
            FROM
                parties_summary
                CROSS JOIN jsonb_array_elements_text(roles) AS ROLE
            GROUP BY
                id,
                ROLE) id_role
        GROUP BY
            id) parties_role_counts USING (id);

CREATE UNIQUE INDEX tmp_release_party_aggregates_id ON tmp_release_party_aggregates (id);

