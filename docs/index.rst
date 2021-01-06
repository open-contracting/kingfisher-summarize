OCDS Kingfisher Summarize
=========================

.. include:: ../README.rst

How it works
------------

Kingfisher Summarize runs SQL statements to create `SQL schemas <https://www.postgresql.org/docs/current/ddl-schemas.html>`__, containing tables and `views <https://en.wikipedia.org/wiki/View_(SQL)>`__, which summarize the OCDS data in specified collections from `Kingfisher Process <https://kingfisher-process.readthedocs.io/>`__.

A SQL schema is like a set of SQL tables in a common namespace. It is not like a set of constraints, like `XML schema <https://en.wikipedia.org/wiki/XML_schema>`__ or `JSON Schema <https://json-schema.org>`__.

The schemas are created in the database used by Kingfisher Process, and the schemas' names start with ``view_data_``. (The default ``public`` schema contains the tables created by Kingfisher Process.)

Typical usage
-------------

Create a schema
~~~~~~~~~~~~~~~

Once Kingfisher Summarize is :doc:`installed<get-started>`, use the :ref:`add` command to create schemas that summarize one or more collections of your choice. (This command might take a long time to run. You might want to run it in a terminal multiplexer like ``tmux``.)

Once it's done, you can query the tables it created.

Query its tables
~~~~~~~~~~~~~~~~

As documented in the :ref:`add` command, the schema you created has a name starting with ``view_data_``, like ``view_data_collection_123`` or ``view_data_collection_4_5_6`` or ``view_data_the_name``. To learn more about each table in the schema, refer to the :doc:`database`.

To query a table in the schema you created, prefix the table name by the schema name and a period. For example:

.. code-block:: sql

   SELECT * FROM view_data_collection_123.release_summary;

Instead of typing the schema name every time, you can set PostgreSQL's `search_path <https://www.postgresql.org/docs/current/runtime-config-client.html#GUC-SEARCH-PATH>`__ to a comma-separated list of schemas in which to search for tables. For example, if you want to query both a Kingfisher Summarize schema and Kingfisher Process' tables, run this statement first:

.. code-block:: sql

   SET search_path = view_data_collection_123, public;

You can then run statements like:

.. code-block:: postgresql

   SELECT * FROM release_summary;
   SELECT * FROM collection;

Remove the schema
~~~~~~~~~~~~~~~~~

Once you no longer need the schema, remove it using the :ref:`remove` command to free up disk space. (You can re-create it at any time using the :ref:`add` command.)

List all schemas
~~~~~~~~~~~~~~~~

To get a list of schemas created by yourself or others, use the :ref:`index` command. It reports:

-  The name of each schema
-  The IDs of the collections that it summarizes
-  The note provided by the user who created it

That's it! Feel free to browse the documentation below.

.. toctree::
   :maxdepth: 2
   :caption: Contents

   get-started
   cli
   database
   querying-data
   logging
   develop/index
   changelog
