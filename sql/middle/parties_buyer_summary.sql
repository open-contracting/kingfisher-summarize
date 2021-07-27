SELECT create_parties('buyer', 'buyer', '', $$
    SELECT
        *,
        data -> 'buyer' AS buyer
    FROM
        tmp_release_summary_with_release_data
$$);
