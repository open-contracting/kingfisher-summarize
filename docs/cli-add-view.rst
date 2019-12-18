Command line tool - Add View
============================

This tool will add a new view.

.. code-block:: shell-session

    python ocdskingfisher-views-cli add-view [viewname] [collection_id1] "[note]"
    python ocdskingfisher-views-cli add-view [viewname] [collection_id1],[collection_id2] "[note]"

For example,

.. code-block:: shell-session

    python ocdskingfisher-views-cli add-view viewname 1,3 "Created by Fred."

The view name must be something that is a valid Postgres schema name. We suggest using numbers, characters and _ only.

You can pass a single collection ID, or multiple collection ID's separated by commas.

Finally, pass a note. This will help people later understand if the data is still in use.

By default, this will then go on to build the data for this view. It does this by effectively calling the following commands, with the default options.

* :doc:`cli-refresh-views`
* :doc:`cli-field-counts`
* :doc:`cli-correct-user-permissions`

If you don't want it do this you can pass the optional ``--dontbuild`` flag. You will then have to run the above commands yourself to get all the data (you must run them in this order).


