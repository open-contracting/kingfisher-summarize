CREATE TABLE tmp_release_milestones_aggregates AS
WITH all_milestone_types AS (
    SELECT
        id,
        "type"
    FROM
        contract_milestones_summary
    UNION ALL
    SELECT
        id,
        "type"
    FROM
        contract_implementation_milestones_summary
    UNION ALL
    SELECT
        id,
        "type"
    FROM
        planning_milestones_summary
    UNION ALL
    SELECT
        id,
        "type"
    FROM
        tender_milestones_summary
)
SELECT
    id,
    jsonb_object_agg( coalesce("type", ''), total_milestoneTypes) milestone_type_counts,
    sum( total_milestoneTypes) total_milestones
FROM (
    SELECT
        id,
        "type",
        count(*) total_milestoneTypes
    FROM
        all_milestone_types
    GROUP BY
        id,
        "type"
) AS d
GROUP BY
    id;

CREATE UNIQUE INDEX tmp_release_milestones_aggregates_id ON tmp_release_milestones_aggregates (id);

