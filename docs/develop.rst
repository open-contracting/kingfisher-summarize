Development
===========

.. _devenv:

Development environment
-----------------------

You need to set up the appropriate development environment to modify Kingfisher Views. You can install the requirements locally, or use the preconfigured Vagrant setup.

Locally, you will need a Postgres installation, as well as `Kingfisher Process <https://kingfisher-process.readthedocs.io/en/latest/requirements-install.html>`__ and `Kingfisher Views <https://kingfisher-views.readthedocs.io/en/latest/get-started.html#install-kingfisher-views>`__ installed in a virtual environment.

We recommend using the Vagrant setup though. `These instructions will get you started with Vagrant for Kingfisher <https://ocdskingfisher.readthedocs.io/en/latest/vagrant.html#>`__. When you are modifying SQL files or source code for Kingfisher Views, do this on your host machine, *not* in the Vagrant environment.

You probably already have a preferred client for working with Postgres databases. The database name, user and password are all :code:`ocdskingfisher`.

Notes on Postgres clients:
  * To use `psql` inside the Vagrant box, solve permissions issues by running :code:`createuser -s vagrant`
  * To use a client like pgadmin with Vagrant, connect on port 7070.

.. _loadingdata:

Loading data
------------

In order to test any changes you're going to make, you need to load some data. The `test data <https://github.com/open-contracting/kingfisher-views/tree/master/tests/fixtures>`__ covers every field in the standard so you can load that, but you may also have some specific data of your own you want to work with.

1. Set up Kingfisher Process:

.. code-block:: bash

    (vagrant) cd /vagrant/process
    (vagrant) source .ve/bin/activate
    // Set up database
    (vagrant) python ocdskingfisher-process-cli upgrade-database
    // Make a new collection
    (vagrant) python ocdskingfisher-process-cli new-collection 'new' '2000-01-01 00:00:00'
    // Populate database
    (vagrant) python ocdskingfisher-process-cli local-load 1 ../views/tests/fixtures release_package

2. Make views on the data. Views tables are created in the general kingfisher database (:code:`ocdskingfisher`, tables :code:`view_data_{collection}`, :code:`view_info`, :code:`view_meta`): 

.. code-block:: bash

    (vagrant) cd ../views
    (vagrant) deactivate && source .ve/bin/activate
    (vagrant) python ocdskingfisher-views-cli add-view 1 "some note"

3. Look at data that has been created, so you have something to compare to when you make changes.
  * Select from :code:`view_data_{collection}` to see views data created so far
  * Select from view :code:`release_summary_with_data`


SQL files
---------

The queries that generate different views are arranged across an ordered series of SQL files in the `sql directory <https://github.com/open-contracting/kingfisher-views/tree/master/sql>`__. In the following documentation, for brevity, the SQL files are referred by their numeric prefix.

The SQL files are run by the :ref:`refresh-views` command.

Note that:

* All SQL files depend on ``001``, which creates functions.
* All SQL files depend on ``002``, which creates ``tmp_release_summary``.
* ``007`` depends on ``006`` (contract summaries need to know about award summaries).
* ``008`` depends on all SQL files (release summaries need to know about all others).
* ``008`` drops ``tmp_release_summary``.

.. _sql-contents:

File and query contents
~~~~~~~~~~~~~~~~~~~~~~~

The SQL files are named after the parts of the OCDS data they concern.

Queries in the files are typically grouped into blocks. A block usually starts with a :code:`drop table if exists...` query and ends with a :code:`create unique index`. This is useful to know if you are copying and pasting existing blocks of queries to add new data to views that is simiarly structured.

In many cases views outputs are generated from multiple places. You'll see table names beginning with :code:`tmp_` or :code:`staged_` which are used as intermediate stores for data as it is aggregated, and dropped at the end of the file.

Run specific files
~~~~~~~~~~~~~~~~~~

If you're working on a specific file, you can run it on its own, using the ``psql`` command. For example, to run the ``004-planning.sql`` file in the ``view_data_the_name`` schema, using the :ref:`default database connection settings<database-connection-settings>`:

.. code-block:: bash

   psql 'dbname=ocdskingfisher options=--search-path=view_data_the_name' -U ocdskingfisher -f 004-planning.sql

To work on a file, you should first run the :ref:`refresh-views` command and then run the ``002`` file. You can then run the file you're working on as often as you want, without repeating the previous steps.

Time SQL statements
~~~~~~~~~~~~~~~~~~~

Add ``-c '\timing'`` to a ``psql`` command, before any ``-f`` options. For example, for the command above:

.. code-block:: bash

   psql 'dbname=ocdskingfisher options=--search-path=view_data_the_name' -U ocdskingfisher -c '\timing' -f 004-planning.sql

Documentation
-------------

Update the database tables reference
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

:doc:`database` displays the CSV files in the `docs/definitions/ <https://github.com/open-contracting/kingfisher-views/tree/master/docs/definitions>`__ directory. To create and/or update the CSV files, run:

.. code-block:: bash

   python ocdskingfisher-views-cli docs-table-ref

Then, for any new CSV file, manually add a new sub-section to ``docs/database.rst`` under an appropriate section.

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
