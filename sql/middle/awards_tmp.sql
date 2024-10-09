CREATE TABLE tmp_awards_summary AS
SELECT
    r.id,
    ordinality - 1 AS award_index,
    r.release_type,
    r.collection_id,
    r.ocid,
    r.release_id,
    r.data_id,
    value AS award
FROM
    tmp_release_summary_with_release_data AS r
CROSS JOIN
    jsonb_array_elements(data -> 'awards')
    WITH ORDINALITY
WHERE
    jsonb_typeof(data -> 'awards') = 'array';

CREATE UNIQUE INDEX tmp_awards_summary_id ON tmp_awards_summary (id, award_index);
