DROP TABLE IF EXISTS tmp_planning_summary;

CREATE TABLE tmp_planning_summary AS
SELECT
    r.id,
    r.release_type,
    r.collection_id,
    r.ocid,
    r.release_id,
    r.data_id,
    data -> 'planning' AS planning
FROM
    tmp_release_summary_with_release_data r
WHERE
    data ? 'planning';

----
CREATE UNIQUE INDEX tmp_planning_summary_id ON tmp_planning_summary (id);

----
DROP TABLE IF EXISTS planning_documents_summary;

CREATE TABLE planning_documents_summary AS
SELECT
    r.id,
    ORDINALITY - 1 AS document_index,
    r.release_type,
    r.collection_id,
    r.ocid,
    r.release_id,
    r.data_id,
    value AS document,
    value ->> 'documentType' AS documentType,
    value ->> 'format' AS format
FROM
    tmp_planning_summary r
    CROSS JOIN jsonb_array_elements(planning -> 'documents')
    WITH ORDINALITY
WHERE
    jsonb_typeof(planning -> 'documents') = 'array';

----
CREATE UNIQUE INDEX planning_documents_summary_id ON planning_documents_summary (id, document_index);

CREATE INDEX planning_documents_summary_data_id ON planning_documents_summary (data_id);

CREATE INDEX planning_documents_summary_collection_id ON planning_documents_summary (collection_id);

----
DROP TABLE IF EXISTS planning_milestones_summary;

CREATE TABLE planning_milestones_summary AS
SELECT
    r.id,
    ORDINALITY - 1 AS milestone_index,
    r.release_type,
    r.collection_id,
    r.ocid,
    r.release_id,
    r.data_id,
    value AS milestone,
    value ->> 'type' AS TYPE,
    value ->> 'code' AS code,
    value ->> 'status' AS status
FROM
    tmp_planning_summary r
    CROSS JOIN jsonb_array_elements(planning -> 'milestones')
    WITH ORDINALITY
WHERE
    jsonb_typeof(planning -> 'milestones') = 'array';

----
CREATE UNIQUE INDEX planning_milestones_summary_id ON planning_milestones_summary (id, milestone_index);

CREATE INDEX planning_milestones_summary_data_id ON planning_milestones_summary (data_id);

CREATE INDEX planning_milestones_summary_collection_id ON planning_milestones_summary (collection_id);

----
DROP TABLE IF EXISTS planning_summary;

CREATE TABLE planning_summary AS
SELECT
    r.id,
    r.release_type,
    r.collection_id,
    r.ocid,
    r.release_id,
    r.data_id,
    convert_to_numeric (planning -> 'budget' -> 'amount' ->> 'amount') planning_budget_amount,
    planning -> 'budget' -> 'amount' ->> 'currency' planning_budget_currency,
    planning -> 'budget' ->> 'projectID' planning_budget_projectID,
    documents_count,
    documentType_counts,
    milestones_count,
    milestoneType_counts
FROM
    tmp_planning_summary r
    LEFT JOIN (
        SELECT
            id,
            jsonb_object_agg(coalesce(documentType, ''), documentType_count) documentType_counts,
            count(*) documents_count
        FROM (
            SELECT
                id,
                documentType,
                count(*) documentType_count
            FROM
                planning_documents_summary
            GROUP BY
                id,
                documentType) AS d
        GROUP BY
            id) documentType_counts USING (id)
    LEFT JOIN (
        SELECT
            id,
            jsonb_object_agg(coalesce(TYPE, ''), milestoneType_count) milestoneType_counts,
            count(*) milestones_count
        FROM (
            SELECT
                id,
                TYPE,
                count(*) milestoneType_count
            FROM
                planning_milestones_summary
            GROUP BY
                id,
                TYPE) AS d
        GROUP BY
            id) milestoneType_counts USING (id);

----
CREATE UNIQUE INDEX planning_summary_id ON planning_summary (id);

CREATE INDEX planning_summary_data_id ON planning_summary (data_id);

CREATE INDEX planning_summary_collection_id ON planning_summary (collection_id);

DROP TABLE IF EXISTS tmp_planning_summary;

