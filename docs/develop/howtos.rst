How-to guides
=============

SQL files
---------

The examples below use the ``view_data_NAME`` schema and the :ref:`default database connection settings<database-connection-settings>`. Change these as needed.

Run a specific file
~~~~~~~~~~~~~~~~~~~

To run, for example, the ``004-planning.sql`` file:

.. code-block:: bash

   psql 'dbname=ocdskingfisher user=ocdskingfisher options=--search-path=view_data_NAME' -f 004-planning.sql

When working on a specific file, you can first run the :ref:`add-view` command and then run the ``002`` file (on which all SQL files depend) as above. You can then run the specific file after each of your changes to see the new results.

Time SQL statements
~~~~~~~~~~~~~~~~~~~

Add the ``-c '\timing'`` option to a ``psql`` command, before any ``-f`` options. For example:

.. code-block:: bash

   psql 'dbname=ocdskingfisher user=ocdskingfisher options=--search-path=view_data_NAME' -c '\timing' -f 004-planning.sql

Drop tables and views
~~~~~~~~~~~~~~~~~~~~~

To undo the ``field_counts`` routine, run:

.. code-block:: sql

  DROP TABLE field_counts;

.. _docs-files:

Documentation files
-------------------

Update the database tables reference
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

:doc:`../database` displays the CSV files in the `docs/definitions/ <https://github.com/open-contracting/kingfisher-views/tree/master/docs/definitions>`__ directory. To create and/or update the CSV files, run (replacing ``COLLECTION_NAME`` below):

.. code-block:: bash

   python ocdskingfisher-views-cli docs-table-ref COLLECTION_NAME

Then, for any new CSV file, manually add a new sub-section to ``docs/database.rst`` under an appropriate section.

.. _create_erd:

Create Entity Relationship Diagram
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#. Install `SchemaSpy <https://schemaspy.readthedocs.io/en/latest/installation.html>`__
#. Download the `PostgreSQL JDBC Driver <https://jdbc.postgresql.org/>`__
#. Move and rename the JAR files into the repository's directory as ``schemaspy.jar`` and ``postgresql.jar``

Add a schema with the ``--tables-only`` option:

.. code-block:: bash

    python ocdskingfisher-views-cli add-view 123 diagram --tables-only

Run SchemaSpy, using appropriate values for the ``-db`` (database name), ``-`` (schema) ``-u`` (user) and ``-p`` (password, optional) arguments:

.. code-block:: bash

   java -jar schemaspy.jar -t pgsql -dp postgresql.jar -host localhost -db ocdskingfisher -s view_data_collection_123 -u ocdskingfisher --password ocdskingfisher -o schemaspy -norows

In the directory that results, copy ``schemaspy/diagrams/summary/relationships.real.compact.png`` to ``docs/_static/erd.png``.
