CREATE TABLE tmp_release_awards_aggregates AS
SELECT
    id,
    count(*) AS award_count,
    min(award_date) AS first_award_date,
    max(award_date) AS last_award_date,
    sum(documents_count) AS total_award_documents,
    sum(items_count) AS total_award_items,
    sum(suppliers_count) AS total_award_suppliers,
    sum(award_value_amount) award_amount
FROM
    awards_summary
GROUP BY
    id;

CREATE UNIQUE INDEX tmp_release_awards_aggregates_id ON tmp_release_awards_aggregates (id);

CREATE TABLE tmp_release_award_suppliers_aggregates AS
SELECT
    id,
    count(DISTINCT unique_identifier_attempt) AS unique_award_suppliers
FROM
    award_suppliers_summary
GROUP BY
    id;

CREATE UNIQUE INDEX tmp_release_award_suppliers_aggregates_id ON tmp_release_award_suppliers_aggregates (id);

CREATE TABLE tmp_award_documents_aggregates AS
SELECT
    id,
    jsonb_object_agg(coalesce(documentType, ''), documentType_count) award_documentType_counts
FROM (
    SELECT
        id,
        documentType,
        count(*) documentType_count
    FROM
        award_documents_summary
    GROUP BY
        id,
        documentType) AS d
GROUP BY
    id;

CREATE UNIQUE INDEX tmp_award_documents_aggregates_id ON tmp_award_documents_aggregates (id);

