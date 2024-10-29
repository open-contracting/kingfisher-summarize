How-to guides
=============

SQL files
---------

The examples below use the ``summary_NAME`` schema and the :ref:`default database connection settings<database-connection-settings>`. Change these as needed.

Run a specific file
~~~~~~~~~~~~~~~~~~~

To run, for example, the ``planning_tmp.sql`` file:

.. code-block:: bash

   psql 'dbname=ocdskingfisher user=ocdskingfisher options=--search-path=summary_NAME' -f planning_tmp.sql

.. note::

   See `issue #167 <https://github.com/open-contracting/kingfisher-summarize/issues/167>`__ about developer tools.

Time SQL statements
~~~~~~~~~~~~~~~~~~~

Add the ``-c '\timing'`` option to a ``psql`` command, before any ``-f`` options. For example:

.. code-block:: bash

   psql 'dbname=ocdskingfisher user=ocdskingfisher options=--search-path=summary_NAME' -c '\timing' -f planning_tmp.sql

Drop tables and views
~~~~~~~~~~~~~~~~~~~~~

To undo a SQL file, drop the tables and views that it creates.

To undo the ``field_counts`` routine, run:

.. code-block:: sql

  DROP TABLE field_counts;

.. _docs-files:

Documentation files
-------------------

Update the Database tables page
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

:doc:`../database` displays the CSV files in the `docs/definitions/ <https://github.com/open-contracting/kingfisher-summarize/tree/main/docs/definitions>`__ directory. To create and/or update the CSV files, run (replacing ``NAME`` below):

.. code-block:: bash

   ./manage.py dev docs-table-ref NAME

Then, for any new CSV file, manually add a new sub-section to ``docs/database.rst`` under an appropriate section.

.. _create-erd:

Update the Entity Relationship Diagram
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Add a schema with the ``--tables-only`` option:

.. code-block:: bash

    ./manage.py add 123 diagram --tables-only

Then, `update <https://ocp-software-handbook.readthedocs.io/en/latest/services/postgresql.html#generate-entity-relationship-diagram>`__ the :ref:`erd`. For example:

.. code-block:: bash

   java -jar schemaspy.jar -t pgsql -dp postgresql.jar -o schemaspy -norows -host localhost -db kingfisher_summarize -s summary_collection_1 -u MYUSER
   mv schemaspy/diagrams/summary/relationships.real.compact.png docs/_static/
