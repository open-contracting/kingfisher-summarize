CREATE TABLE tmp_awards_aggregates AS
SELECT
    id,
    count(*) AS total_awards,
    min(date) AS first_award_date,
    max(date) AS last_award_date,
    sum(total_documents) AS total_award_documents,
    sum(total_items) AS total_award_items,
    sum(total_suppliers) AS total_award_suppliers,
    sum(value_amount) AS sum_awards_value_amount
FROM
    awards_summary
GROUP BY
    id;

CREATE UNIQUE INDEX tmp_awards_aggregates_id ON tmp_awards_aggregates (id);

CREATE TABLE tmp_award_suppliers_aggregates AS
SELECT
    id,
    count(DISTINCT unique_identifier_attempt) AS total_unique_award_suppliers
FROM
    award_suppliers_summary
GROUP BY
    id;

CREATE UNIQUE INDEX tmp_award_suppliers_aggregates_id ON tmp_award_suppliers_aggregates (id);

CREATE TABLE tmp_award_documents_aggregates AS
SELECT
    id,
    jsonb_object_agg(coalesce(documenttype, ''), total_documenttypes) AS award_document_documenttype_counts
FROM (
    SELECT
        id,
        documenttype,
        count(*) AS total_documenttypes
    FROM
        award_documents_summary
    GROUP BY
        id,
        documenttype
) AS d
GROUP BY
    id;

CREATE UNIQUE INDEX tmp_award_documents_aggregates_id ON tmp_award_documents_aggregates (id);
