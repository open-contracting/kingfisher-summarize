SELECT create_parties('tenderer', 'tenderers', 'tenderer_index,', $$
    SELECT
        rs.*,
        value AS tenderer,
        ORDINALITY - 1 AS tenderer_index
    FROM
        tmp_release_summary_with_release_data rs
        CROSS JOIN jsonb_array_elements(data -> 'tender' -> 'tenderers') WITH ORDINALITY
    WHERE
        jsonb_typeof(data -> 'tender' -> 'tenderers') = 'array'
$$);
