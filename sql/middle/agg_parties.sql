CREATE TABLE tmp_release_party_aggregates AS
SELECT
    id,
    parties_role_counts,
    total_parties_roles,
    total_parties
FROM (
    SELECT
        id,
        count(*) AS total_parties
    FROM
        parties_summary
    GROUP BY
        id
) AS total_parties
LEFT JOIN (
    SELECT
        id,
        sum(total_parties_roles) AS total_parties_roles,
        jsonb_object_agg(coalesce(role, ''), total_parties_roles) AS parties_role_counts
    FROM (
        SELECT
            id,
            role,
            count(*) AS total_parties_roles
        FROM
            parties_summary
        -- https://github.com/sqlfluff/sqlfluff/issues/4623#issuecomment-2401209085
        CROSS JOIN jsonb_array_elements_text(roles) AS role -- noqa: AL05
        GROUP BY
            id,
            role
    ) AS id_role
    GROUP BY
        id
) AS parties_role_counts USING (id);

CREATE UNIQUE INDEX tmp_release_party_aggregates_id ON tmp_release_party_aggregates (id);
