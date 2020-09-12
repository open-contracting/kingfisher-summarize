How-To Guides
=============

SQL files
---------

The examples use the ``view_data_NAME`` schema and the :ref:`default database connection settings<database-connection-settings>`. Change these as needed.

Run a specific file
~~~~~~~~~~~~~~~~~~~

To run, for example, the ``004-planning.sql`` file:

.. code-block:: bash

   psql 'dbname=ocdskingfisher user=ocdskingfisher options=--search-path=view_data_NAME' -f 004-planning.sql

When working on a specific file, you can first run the :ref:`refresh-views` command and then run the ``002`` file (on which all SQL files depend) as above. You can then run the specific file after each change to see the new results.

Time SQL statements
~~~~~~~~~~~~~~~~~~~

Add the ``-c '\timing'`` option to a ``psql`` command, before any ``-f`` options. For example:

.. code-block:: bash

   psql 'dbname=ocdskingfisher user=ocdskingfisher options=--search-path=view_data_NAME' -c '\timing' -f 004-planning.sql
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

`Follow these instructions <https://kingfisher-process.readthedocs.io/en/latest/development.html#updating-database-tables-graphic>`__ to install `SchemaSpy <http://schemaspy.org/>`__.

Add a schema with the ``--tables-only`` option:

.. code-block:: bash

    python ocdskingfisher-views-cli add-view 123 "The note" --name <view_name> --tables-only

Run SchemaSpy with:

.. code-block:: bash

   java -jar /bin/schemaspy.jar -t pgsql -dp /bin/postgresql.jar -s view_data_<view_name> -db ocdskingfisher -u ocdskingfisher -p ocdskingfisher -host localhost -o /vagrant/schemaspy -norows

In the directory that results, copy ``schemaspy/diagrams/summary/relationships.real.compact.png`` to ``docs/_static/erd.png``.