CREATE TABLE tmp_release_party_aggregates AS
SELECT
    id,
    role_counts,
    total_roles,
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
            sum(total_roles) AS total_roles,
            jsonb_object_agg(coalesce(ROLE, ''), total_roles) role_counts
        FROM (
            SELECT
                id,
                ROLE,
                count(*) total_roles
            FROM
                parties_summary
                CROSS JOIN jsonb_array_elements_text(roles) AS ROLE
            GROUP BY
                id,
                ROLE) id_role
        GROUP BY
            id) role_counts USING (id);

CREATE UNIQUE INDEX tmp_release_party_aggregates_id ON tmp_release_party_aggregates (id);

