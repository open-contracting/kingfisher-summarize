Development
===========

SQL files
---------

The SQL files in the `sql directory <https://github.com/open-contracting/kingfisher-views/tree/master/sql>`__ are run by the :ref:`refresh-views` command.

Run specific files
~~~~~~~~~~~~~~~~~~

If you're working on a specific file, you can run it on its own, using the ``psql`` command. For example, to run the ``004-planning.sql`` file in the ``view_data_the_name`` schema, using the :ref:`default database connection settings<database-connection-settings>`:

.. code-block:: bash

   psql 'dbname=ocdskingfisher user=ocdskingfisher options=--search-path=view_data_the_name' -f 004-planning.sql

Note that (for brevity, SQL files are referred by their numeric prefix):

* All SQL files depend on ``001``, which creates functions.
* All SQL files depend on ``002``, which creates ``tmp_release_summary``.
* ``007`` depends on ``006`` (contract summaries need to know about award summaries).
* ``008`` depends on all SQL files (release summaries need to know about all others).
* ``008`` drops ``tmp_release_summary``.

In other words, to work on a file, you should first run the :ref:`refresh-views` command and then run the ``002`` file. You can then run the file you're working on as often as you want, without repeating the previous steps.

Time SQL statements
~~~~~~~~~~~~~~~~~~~

Add ``-c '\timing'`` to a ``psql`` command, before any ``-f`` options. For example, for the command above:

.. code-block:: bash

   psql 'dbname=ocdskingfisher user=ocdskingfisher options=--search-path=view_data_the_name' -c '\timing' -f 004-planning.sql

Documentation files
-------------------

Update the database tables reference
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

:doc:`database` displays the CSV files in the `docs/definitions/ <https://github.com/open-contracting/kingfisher-views/tree/master/docs/definitions>`__ directory. To create and/or update the CSV files, run:

.. code-block:: bash

   python ocdskingfisher-views-cli docs-table-ref

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

Configuration tables
--------------------

Add a migration
~~~~~~~~~~~~~~~

Creates a generic `Alembic <https://alembic.sqlalchemy.org/>`__ migration file in the `ocdskingfisherviews/migrations/versions/ <https://github.com/open-contracting/kingfisher-views/tree/master/ocdskingfisherviews/migrations/versions>`__ directory. Replace ``MESSAGE`` with a brief description of what the migration does, and run:

.. code-block:: bash

   alembic --raiseerr --config ocdskingfisherviews/alembic.ini revision -m 'MESSAGE'

Remove the tables
~~~~~~~~~~~~~~~~~

Removes Kingfisher Views' :doc:`configuration tables<setup>`:

.. code-block:: bash

   alembic --raiseerr --config ocdskingfisherviews/alembic.ini downgrade base

See :ref:`refresh-views` and :ref:`field-counts` to remove collection-specific schemas.
