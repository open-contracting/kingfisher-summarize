CREATE TABLE contract_implementation_transactions_summary AS
SELECT
    r.id,
    contract_index,
    ORDINALITY - 1 AS transaction_index,
    r.release_type,
    r.collection_id,
    r.ocid,
    r.release_id,
    r.data_id,
    convert_to_numeric (coalesce(value -> 'value' ->> 'amount', value -> 'amount' ->> 'amount')) transaction_value_amount,
    coalesce(value -> 'value' ->> 'currency', value -> 'amount' ->> 'currency') transaction_value_currency,
    value AS transaction
FROM
    tmp_contracts_summary r
    CROSS JOIN jsonb_array_elements(contract -> 'implementation' -> 'transactions')
    WITH ORDINALITY
WHERE
    jsonb_typeof(contract -> 'implementation' -> 'transactions') = 'array';

CREATE UNIQUE INDEX contract_implementation_transactions_summary_id ON contract_implementation_transactions_summary (id, contract_index, transaction_index);

CREATE INDEX contract_implementation_transactions_summary_data_id ON contract_implementation_transactions_summary (data_id);

CREATE INDEX contract_implementation_transactions_summary_collection_id ON contract_implementation_transactions_summary (collection_id);

