CREATE TABLE tmp_planning_summary AS
SELECT
    r.id,
    r.release_type,
    r.collection_id,
    r.ocid,
    r.release_id,
    r.data_id,
    r.data -> 'planning' AS planning
FROM
    tmp_release_summary_with_release_data AS r
WHERE
    r.data ? 'planning';

CREATE UNIQUE INDEX tmp_planning_summary_id ON tmp_planning_summary (id);
