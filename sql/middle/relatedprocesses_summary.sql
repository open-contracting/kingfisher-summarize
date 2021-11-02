CREATE TABLE relatedprocesses_summary AS
SELECT
    r.id,
    ORDINALITY - 1 AS relatedprocess_index,
    r.release_type,
    r.collection_id,
    r.ocid,
    r.release_id,
    r.data_id,
    value AS relatedprocess,
    value ->> 'id' AS relatedprocess_id,
    value -> 'relationship' AS relationship,
    value ->> 'title' AS title,
    value ->> 'scheme' AS scheme,
    value ->> 'identifier' AS identifier,
    value ->> 'uri' AS uri
FROM
    tmp_release_summary_with_release_data r
    CROSS JOIN jsonb_array_elements(data -> 'relatedProcesses')
    WITH ORDINALITY
WHERE
    jsonb_typeof(data -> 'relatedProcesses') = 'array';

CREATE UNIQUE INDEX related_processes_summary_id ON relatedprocesses_summary (id, relatedprocess_index);

CREATE INDEX related_processes_summary_data_id ON relatedprocesses_summary (data_id);

CREATE INDEX related_processes_summary_collection_id ON relatedprocesses_summary (collection_id);

