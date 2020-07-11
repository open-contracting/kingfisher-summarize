Setup
=====

Prerequisites
-------------

You can either install all requirements manually or use the `preconfigured Vagrant setup <https://kingfisher-vagrant.readthedocs.io/en/latest/>`__.

To install manually, follow the `Get Started <https://kingfisher-views.readthedocs.io/en/latest/get-started.html>`__ guide.

When using Vagrant, remember to modify Kingfisher Views's SQL files and source code **on your host machine**, not in the Vagrant environment. See also how to `access the database <https://kingfisher-vagrant.readthedocs.io/en/latest/#working-with-the-database>`__ in Vagrant.

.. _load-data:

Load data
---------

To test your changes, you need to have some data loaded. The `test data <https://github.com/open-contracting/kingfisher-views/tree/master/tests/fixtures>`__ covers common fields, but you might have specific data that you want to test against.

#. Set up Kingfisher Process' database, create a collection, and load the test data into it:

   .. code-block:: bash

      (vagrant) cd /vagrant/process
      (vagrant) source .ve/bin/activate
      (vagrant) python ocdskingfisher-process-cli upgrade-database
      (vagrant) python ocdskingfisher-process-cli new-collection '{collection_name}' '2000-01-01 00:00:00'
      (vagrant) python ocdskingfisher-process-cli local-load 1 ../views/tests/fixtures release_package
      (vagrant) deactivate

#. Summarize collection 1 using Kingfisher Views:

   .. code-block:: bash

      (vagrant) cd /vagrant/views
      (vagrant) source .ve/bin/activate
      (vagrant) python ocdskingfisher-views-cli add-view 1 "some note"

#. Look at the data that has been created, so you have something to compare against when you make changes.

   -  Select from tables in the ``view_data_collection_1`` schema
   -  Select from the table ``release_summary_with_data``

SQL files
---------

The SQL statements that summarize data are stored in a sequence of SQL files in the `sql directory <https://github.com/open-contracting/kingfisher-views/tree/master/sql>`__. For brevity, the SQL files are referred here by their numeric prefix. The :ref:`refresh-views` command runs the SQL files.

Dependencies
~~~~~~~~~~~~

-  All SQL files depend on ``001``, which creates SQL functions.
-  All SQL files depend on ``002``, which creates ``tmp_release_summary``.
-  ``007`` depends on ``006`` (contract summaries need to know about award summaries).
-  ``008`` depends on all SQL files (release summaries need to know about all others).
-  ``008`` drops ``tmp_release_summary``.

.. _sql-contents:

Contents
~~~~~~~~

SQL files are named after the sections of the OCDS data that they summarize. The ``008-release.sql`` file summarizes the entire collection(s).

SQL statements are typically grouped into blocks. A block typically starts with ``drop table if exists`` and ends with ``create unique index``. Make sure to copy-paste the entire block when adding a similar summary.

In ``008-release.sql``, blocks are ordered in roughly the same order as the stages of a contracting process.

In many cases, the final tables are generated from many others. Table names starting with ``tmp_`` or ``staged_`` are temporary or intermediate tables that are typically dropped at the end of the file in which they are created.

In some cases, ``----`` lines break the files into segments, each of which are executed in a transaction.

Run a specific file
~~~~~~~~~~~~~~~~~~~

To run, for example, the ``004-planning.sql`` file in the ``view_data_the_name`` schema using the :ref:`default database connection settings<database-connection-settings>`:

.. code-block:: bash

   psql 'dbname=ocdskingfisher user=ocdskingfisher options=--search-path=view_data_the_name' -f 004-planning.sql

When working on a specific file, you can first run the :ref:`refresh-views` command and then run the ``002`` file as above. You can then run the specific file after each change to see the new results.

Time SQL statements
~~~~~~~~~~~~~~~~~~~

Add the ``-c '\timing'`` option to a ``psql`` command, before any ``-f`` options. For example:

.. code-block:: bash

   psql 'dbname=ocdskingfisher user=ocdskingfisher options=--search-path=view_data_the_name' -c '\timing' -f 004-planning.sql

.. _docs-files:

Documentation files
-------------------

Update the database tables reference
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

:doc:`../database` displays the CSV files in the `docs/definitions/ <https://github.com/open-contracting/kingfisher-views/tree/master/docs/definitions>`__ directory. To create and/or update the CSV files, run:

.. code-block:: bash

   python ocdskingfisher-views-cli docs-table-ref {collection_name}

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

Removes Kingfisher Views' :doc:`configuration tables<../cli/setup>`:

.. code-block:: bash

   alembic --raiseerr --config ocdskingfisherviews/alembic.ini downgrade base

See :ref:`refresh-views` and :ref:`field-counts` to remove collection-specific schemas.
