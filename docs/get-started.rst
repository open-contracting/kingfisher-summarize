Get started
===========

Prerequisites
-------------

To use Kingfisher Views, you need:

-  Access to a `Unix-like shell <https://en.wikipedia.org/wiki/Shell_(computing)>`__ (some are available for Windows)
-  `Git <https://git-scm.com>`__
-  `Python <https://www.python.org/>`__ 3.6 or greater
-  `PostgreSQL <https://www.postgresql.org>`__ 10 or greater
-  `A Kingfisher Process database <https://kingfisher-process.readthedocs.io/en/latest/requirements-install.html>`__

.. _install:

Install Kingfisher Views
------------------------

Open a shell, and run:

.. code-block:: bash

   git clone https://github.com/open-contracting/kingfisher-views.git
   cd kingfisher-views
   pip install -r requirements.txt

All instructions in this documentation assume that you have changed to the ``kingfisher-views`` directory (the ``cd`` command above).

.. _configure:

Configure Kingfisher Views
--------------------------

Create the configuration directory:

.. code-block:: bash

    mkdir ~/.config/ocdskingfisher-views

.. _config-logging:

Logging
~~~~~~~

Logging from the :doc:`cli/index` can be configured with a ``~/.config/ocdskingfisher-views/logging.json`` file. To download the default configuration::

    curl https://raw.githubusercontent.com/open-contracting/kingfisher-views/master/samples/logging.json -o ~/.config/ocdskingfisher-views/logging.json

To download a different configuration that includes debug messages::

    curl https://raw.githubusercontent.com/open-contracting/kingfisher-views/master/samples/logging-debug.json -o ~/.config/ocdskingfisher-views/logging.json

Read more about :doc:`logging`.

.. _database-connection-settings:

Database connection
~~~~~~~~~~~~~~~~~~~

The database connection is configured by setting the ``KINGFISHER_VIEWS_DATABASE_URL`` environment variable to the `connection URI <https://www.postgresql.org/docs/current/libpq-connect.html#id-1.7.3.8.3.6>`__ of the database used by `Kingfisher Process <https://kingfisher-process.readthedocs.io/en/latest/config.html#postgresql>`__.

It can be set on the command line. For example:

.. code-block:: bash

   export KINGFISHER_VIEWS_DATABASE_URL=postgresql://user:password@localhost:5432/dbname

Or, it can be set in a ``.env`` file in the ``kingfisher-views`` directory. For example:

.. code-block:: none

   KINGFISHER_VIEWS_DATABASE_URL=postgresql://user:password@localhost:5432/dbname

If you prefer not to store the password in the ``.env`` file, you can use the `PostgreSQL Password File <https://www.postgresql.org/docs/11/libpq-pgpass.html>`__, ``~/.pgpass``.

The database user must have the `CREATE privilege <https://www.postgresql.org/docs/current/ddl-priv.html>`__ on the database used by Kingfisher Process. For example, for the default database connection settings:

.. code-block:: bash

   psql ocdskingfisher -U ocdskingfisher -c 'GRANT CREATE ON DATABASE ocdskingfisher TO ocdskingfisher;'

Setup PostgreSQL database
-------------------------

#. Connect to the database as the ``postgres`` user. For example, as a sudoer, run:

   .. code-block:: bash

      su - postgres -c 'psql ocdskingfisher'

#. `Create <https://www.postgresql.org/docs/current/sql-createschema.html>`__ the ``views`` schema, and set it to be owned by the database user configured above. For example, run:

   .. code-block:: sql

      CREATE SCHEMA views AUTHORIZATION ocdskingfisher;

#. Close your PostgreSQL session, e.g. with ``Ctrl-D`` for both

#. Create Kingfisher Views' configuration tables using the :ref:`install` command:

   .. code-block:: bash

      python ocdskingfisher-views-cli install

You're now ready to :doc:`use Kingfisher Views<cli/use>`.

.. note::

   If you notice slow queries and are using solid-state drives, consider tuning PostgreSQL by decreasing ``random_page_cost``:

   .. code-block:: bash

      ALTER TABLESPACE pg_default SET (random_page_cost = 2.0);
