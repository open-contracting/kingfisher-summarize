CREATE TABLE tmp_contracts_aggregates AS
SELECT
    id,
    count(*) AS total_contracts,
    sum(link_to_awards) AS total_contract_link_to_awards,
    min(datesigned) AS first_contract_datesigned,
    max(datesigned) AS last_contract_datesigned,
    sum(total_documents) AS total_contract_documents,
    sum(total_milestones) AS total_contract_milestones,
    sum(total_items) AS total_contract_items,
    sum(value_amount) AS sum_contracts_value_amount,
    sum(total_implementation_documents) AS total_contract_implementation_documents,
    sum(total_implementation_milestones) AS total_contract_implementation_milestones,
    sum(total_implementation_transactions) AS total_contract_implementation_transactions
FROM
    contracts_summary
GROUP BY
    id;

CREATE UNIQUE INDEX tmp_contracts_aggregates_id ON tmp_contracts_aggregates (id);

CREATE TABLE tmp_contract_documents_aggregates AS
SELECT
    id,
    jsonb_object_agg(coalesce(documenttype, ''), total_documenttypes) AS contract_document_documenttype_counts
FROM (
    SELECT
        id,
        documenttype,
        count(*) AS total_documenttypes
    FROM
        contract_documents_summary
    GROUP BY
        id,
        documenttype
) AS d
GROUP BY
    id;

CREATE UNIQUE INDEX tmp_contract_documents_aggregates_id ON tmp_contract_documents_aggregates (id);

CREATE TABLE tmp_contract_implementation_documents_aggregates AS
SELECT
    id,
    jsonb_object_agg(coalesce(documenttype, ''), total_documenttypes) AS contract_implementation_document_documenttype_counts
FROM (
    SELECT
        id,
        documenttype,
        count(*) AS total_documenttypes
    FROM
        contract_implementation_documents_summary
    GROUP BY
        id,
        documenttype
) AS d
GROUP BY
    id;

CREATE UNIQUE INDEX tmp_contract_implementation_documents_aggregates_id ON tmp_contract_implementation_documents_aggregates (id);

CREATE TABLE tmp_contract_milestones_aggregates AS
SELECT
    id,
    jsonb_object_agg(coalesce(type, ''), total_milestonetypes) AS contract_milestone_type_counts
FROM (
    SELECT
        id,
        type,
        count(*) AS total_milestonetypes
    FROM
        contract_milestones_summary
    GROUP BY
        id,
        type
) AS d
GROUP BY
    id;

CREATE UNIQUE INDEX tmp_contract_milestones_aggregates_id ON tmp_contract_milestones_aggregates (id);

CREATE TABLE tmp_contract_implementation_milestones_aggregates AS
SELECT
    id,
    jsonb_object_agg(coalesce(type, ''), total_milestonetypes) AS contract_implementation_milestone_type_counts
FROM (
    SELECT
        id,
        type,
        count(*) AS total_milestonetypes
    FROM
        contract_implementation_milestones_summary
    GROUP BY
        id,
        type
) AS d
GROUP BY
    id;

CREATE UNIQUE INDEX tmp_contract_implementation_milestones_aggregates_id ON tmp_contract_implementation_milestones_aggregates (id);
