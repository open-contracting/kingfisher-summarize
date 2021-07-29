SELECT create_parties('procuringEntity', 'procuringEntity', '', $$
    SELECT
        *,
        data -> 'tender' -> 'procuringEntity' AS procuringEntity
    FROM
        tmp_release_summary_with_release_data

$$);
