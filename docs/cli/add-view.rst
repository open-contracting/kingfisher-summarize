Add View
========

This tool will add a new view.

.. code-block:: shell-session

    python ocdskingfisher-views-cli add-view [collection_id1] "[note]"
    python ocdskingfisher-views-cli add-view [collection_id1],[collection_id2] "[note]"

For example,

.. code-block:: shell-session

    python ocdskingfisher-views-cli add-view 1,3 "Created by Fred."

This will create a schema called `view_data_collection_1_3`. You can pass a single collection ID, or multiple collection ID's separated by commas.

If you select more than 5 collections or if you want to choose your own view name you can pass a --name argument. The view name must be something that is a valid Postgres schema name. We suggest using numbers, characters and _ only.

.. code-block:: shell-session

    python ocdskingfisher-views-cli add-view --name my_view 1,2,3,4,5,6 "Created by Fred."

This will create a schema called `view_data_my_view`.

Finally, pass a note. This will help people later understand if the data is still in use.

By default, this will then go on to build the data for this view. It does this by effectively calling the following commands, with the default options.

* :doc:`refresh-views`
* :doc:`field-counts`
* :doc:`correct-user-permissions`

If you don't want it do this you can pass the optional ``--dontbuild`` flag. You will then have to run the above commands yourself to get all the data (you must run them in this order).
