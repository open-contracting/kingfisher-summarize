Command-line tools
==================

The ``manage.py`` script at the root of the repository provides access to a suite of command-line tools to create and manage the :doc:`summary tables<database>` of one or more collections.

To see all available commands, change to the directory containing your copy of the repository, and run:

.. code-block:: bash

   ./manage.py --help

To see the help message for a specific command, run, for example:

.. code-block:: bash

   ./manage.py add --help

.. _add:

add
---

Creates a schema containing :doc:`summary tables<database>` about one or more collections.

This command will fail if the schema already exists.

.. note::

   If you notice slow queries and are using solid-state drives, consider tuning PostgreSQL by decreasing ``random_page_cost``:

   .. code-block:: bash

      ALTER TABLESPACE pg_default SET (random_page_cost = 1.0);

.. summarize-one-collection:

Summarize one collection
~~~~~~~~~~~~~~~~~~~~~~~~

Replace ``ID`` with a Kingfisher Process collection ID, replace ``NOTE`` with your name and a description of your purpose, and run:

.. code-block:: bash

   ./manage.py add ID "NOTE"

For example:

.. code-block:: bash

   ./manage.py add 123 "Created by Morgan A. to measure procurement indicators"

This creates a schema named ``view_data_collection_123``.

.. _set-schema-name:

Customize the schema's name
^^^^^^^^^^^^^^^^^^^^^^^^^^^

To customize the last part of the schema's name (for example, ``collection_123`` in ``view_data_collection_123``), set the ``--name`` argument to `a string of letters, numbers and/or underscores <https://www.postgresql.org/docs/current/sql-syntax-lexical.html#SQL-SYNTAX-IDENTIFIERS>`__. For example:

.. code-block:: bash

    ./manage.py add 123 "The note" --name the_name

This creates a schema named ``view_data_the_name``.

.. _summarize-many-collections:

Summarize many collections
~~~~~~~~~~~~~~~~~~~~~~~~~~

Instead of passing one collection ID, you can pass many collection IDs, separated by commas. For example:

.. code-block:: bash

   ./manage.py add 4,5,6 "Created by Morgan A. to compare field coverage"

This creates a schema named ``view_data_collection_4_5_6``.

If you need to summarize more than five collections, then you must :ref:`customize the schema's name<set-schema-name>`.

.. _tables-only:

Create persistent tables for all summary tables
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

By default, some summary tables are database `views <https://www.postgresql.org/docs/current/sql-createview.html>`__ and not persistent `tables <https://www.postgresql.org/docs/current/sql-createtable.html>`__, in order to save disk space.  Use the ``--tables-only`` option to make all summary tables into persistent tables.

.. code-block:: bash

    ./manage.py add 123 "The note" --name the_name --tables-only

Use this option if:

-  You want to allow a user to access the schema's tables, but not Kingfisher Process' tables
-  You want to make it easier for a user to discover the foreign key relationships between tables (for example, using ``\d <table>`` instead of ``\d+ <view>`` followed by ``\d <table>``)
-  You are :ref:`creating the Entity Relationship Diagram<create_erd>`

.. _field-lists:

Calculate JSON paths in each JSON object in each summary table
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The ``--field-lists`` option adds a ``field_list`` column to each summary table, which contains all JSON paths (excluding array indices) in the object that the row describes. For example, a ``field_list`` value in the ``awards_summary`` table will contain the JSON paths in an award object. A ``field_list`` value is a JSONB object in which keys are paths and values are ``NULL``.

.. code-block:: bash

    ./manage.py add 123 "The note" --field-lists

This can be used to check for the presence of multiple fields.  For example, to count the number of awards that have at least one document with an ``id`` and at least one item with an ``id``, run:

.. code-block:: sql

   SELECT count(*) FROM view_data_collection_1.awards_summary WHERE field_list ?& ARRAY['documents/id', 'items/id'];

This could also be written as:

.. code-block:: sql

   SELECT count(*) FROM view_data_collection_1.awards_summary WHERE field_list ? 'documents/id' AND field_list ? 'items/id';

The ``?&`` operator tests whether *all* keys in the right-hand array exist in the left-hand object.  The ``?`` operator tests whether one key exists in the left-hand object.

To count the number of awards that have either at least one document with an ``id`` or at least one item with an ``id``, run:

.. code-block:: sql

   SELECT count(*) FROM view_data_collection_1.awards_summary WHERE field_list ?| ARRAY['documents/id', 'items/id'];

This could also be written as:

.. code-block:: sql

   SELECT count(*) FROM view_data_collection_1.awards_summary WHERE field_list ? 'documents/id' OR field_list ? 'items/id';

The ``?|`` operator tests whether *any* key in the right-hand array exists in the left-hand object.

.. _remove:

remove
------

Drops a schema.

Replace ``NAME`` with the last part of a schema's name (the part after ``view_data_``), and run:

.. code-block:: bash

   ./manage.py remove NAME

This is equivalent to:

.. code-block:: sql

  DROP SCHEMA view_data_NAME CASCADE;

.. _index:

index
-----

Lists the schemas, with collection IDs and creator's notes.

.. code-block:: bash

   ./manage.py index

Outputs:

.. code-block:: none

   | Name             |   Collections | Note                                                                         |
   |------------------|---------------|------------------------------------------------------------------------------|
   | collection_4_5_6 | 4, 5, 6       | Created by Morgan A. to compare field coverage (2020-07-31 14:53:38)         |
   | collection_123   | 1             | Created by Morgan A. to measure procurement indicators (2020-01-02 03:04:05) |

To list the schemas only, Connect to the database used by Kingfisher Summarize, using the connecting settings you :ref:`configured earlier<database-connection-settings>`, and run:

.. code-block:: none

   \dn

.. _upgrade-app:

Upgrade Kingfisher Summarize
----------------------------

If the new version of Kingfisher Summarize makes changes to SQL statements, you might want to re-create the collection-specific schemas, by running :ref:`remove` then :ref:`add` for the selected extensions (``SELECT id from selected_collections;``).
