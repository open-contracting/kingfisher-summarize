CREATE TABLE tmp_release_contracts_aggregates AS
SELECT
    id,
    count(*) AS contract_count,
    sum(link_to_awards) total_contract_link_to_awards,
    sum(contract_value_amount) contract_amount,
    min(datesigned) AS first_contract_datesigned,
    max(datesigned) AS last_contract_datesigned,
    sum(documents_count) AS total_contract_documents,
    sum(milestones_count) AS total_contract_milestones,
    sum(items_count) AS total_contract_items,
    sum(implementation_documents_count) AS total_contract_implementation_documents,
    sum(implementation_milestones_count) AS total_contract_implementation_milestones
FROM
    contracts_summary
GROUP BY
    id;

CREATE UNIQUE INDEX tmp_release_contracts_aggregates_id ON tmp_release_contracts_aggregates (id);

CREATE TABLE tmp_contract_documents_aggregates AS
SELECT
    id,
    jsonb_object_agg(coalesce(documentType, ''), documentType_count) contract_documentType_counts
FROM (
    SELECT
        id,
        documentType,
        count(*) documentType_count
    FROM
        contract_documents_summary
    GROUP BY
        id,
        documentType) AS d
GROUP BY
    id;

CREATE UNIQUE INDEX tmp_contract_documents_aggregates_id ON tmp_contract_documents_aggregates (id);

CREATE TABLE tmp_contract_implementation_documents_aggregates AS
SELECT
    id,
    jsonb_object_agg(coalesce(documentType, ''), documentType_count) contract_implementation_documenttype_counts
FROM (
    SELECT
        id,
        documentType,
        count(*) documentType_count
    FROM
        contract_implementation_documents_summary
    GROUP BY
        id,
        documentType) AS d
GROUP BY
    id;

CREATE UNIQUE INDEX tmp_contract_implementation_documents_aggregates_id ON tmp_contract_implementation_documents_aggregates (id);

CREATE TABLE tmp_contract_milestones_aggregates AS
SELECT
    id,
    jsonb_object_agg(coalesce(TYPE, ''), milestoneType_count) contract_milestoneType_counts
FROM (
    SELECT
        id,
        TYPE,
        count(*) milestoneType_count
    FROM
        contract_milestones_summary
    GROUP BY
        id,
        TYPE) AS d
GROUP BY
    id;

CREATE UNIQUE INDEX tmp_contract_milestones_aggregates_id ON tmp_contract_milestones_aggregates (id);

CREATE TABLE tmp_contract_implementation_milestones_aggregates AS
SELECT
    id,
    jsonb_object_agg(coalesce(TYPE, ''), milestoneType_count) contract_implementation_milestoneType_counts
FROM (
    SELECT
        id,
        TYPE,
        count(*) milestoneType_count
    FROM
        contract_implementation_milestones_summary
    GROUP BY
        id,
        TYPE) AS d
GROUP BY
    id;

CREATE UNIQUE INDEX tmp_contract_implementation_milestones_aggregates_id ON tmp_contract_implementation_milestones_aggregates (id);

