SELECT create_parties('supplier', 'award_suppliers', 'award_index, supplier_index,', $$
    SELECT
        tas.*,
        value AS supplier,
        ORDINALITY - 1 AS supplier_index
    FROM
        tmp_awards_summary tas
        CROSS JOIN jsonb_array_elements(award -> 'suppliers') WITH ORDINALITY
    WHERE
        jsonb_typeof(award -> 'suppliers') = 'array'
$$);
