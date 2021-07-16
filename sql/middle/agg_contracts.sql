CREATE TABLE tmp_release_contracts_aggregates AS
SELECT
    id,
    count(*) AS total_contracts,
    sum(link_to_awards) total_contract_link_to_awards,
    min(datesigned) AS first_contract_datesigned,
    max(datesigned) AS last_contract_datesigned,
    sum(total_documents) AS total_contract_documents,
    sum(total_milestones) AS total_contract_milestones,
    sum(total_items) AS total_contract_items,
    sum(value_amount) sum_contracts_value_amount,
    sum(total_implementation_documents) AS total_contract_implementation_documents,
    sum(total_implementation_milestones) AS total_contract_implementation_milestones
FROM
    contracts_summary
GROUP BY
    id;

CREATE UNIQUE INDEX tmp_release_contracts_aggregates_id ON tmp_release_contracts_aggregates (id);

CREATE TABLE tmp_contract_documents_aggregates AS
SELECT
    id,
    jsonb_object_agg(coalesce(documentType, ''), total_documentTypes) contract_documentType_counts
FROM (
    SELECT
        id,
        documentType,
        count(*) total_documentTypes
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
    jsonb_object_agg(coalesce(documentType, ''), total_documentTypes) contract_implementation_documenttype_counts
FROM (
    SELECT
        id,
        documentType,
        count(*) total_documentTypes
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
    jsonb_object_agg(coalesce(TYPE, ''), total_milestoneTypes) contract_milestoneType_counts
FROM (
    SELECT
        id,
        TYPE,
        count(*) total_milestoneTypes
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
    jsonb_object_agg(coalesce(TYPE, ''), total_milestoneTypes) contract_implementation_milestoneType_counts
FROM (
    SELECT
        id,
        TYPE,
        count(*) total_milestoneTypes
    FROM
        contract_implementation_milestones_summary
    GROUP BY
        id,
        TYPE) AS d
GROUP BY
    id;

CREATE UNIQUE INDEX tmp_contract_implementation_milestones_aggregates_id ON tmp_contract_implementation_milestones_aggregates (id);

