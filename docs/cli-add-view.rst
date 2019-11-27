Command line tool - Add View
============================

This tool will add a new view.

.. code-block:: shell-session

    python ocdskingfisher-views-cli add-view viewname 1,3 "Created by Fred."

The view name must be something that is a valid Postgres schema name. We suggest using numbers, characters and _ only.

You can pass a single collection ID, or multiple collection ID's separated by commas.

Finally, pass a note. This will help people later understand if the data is still in use.
