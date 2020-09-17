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

Download the sample configuration file to the configuration directory:

.. code-block:: bash

    curl -o ~/.config/ocdskingfisher-views/config.ini https://kingfisher-views.readthedocs.io/en/latest/_static/config.ini

.. _config-logging:

Logging
~~~~~~~

Logging from the :doc:`cli/index` can be configured with a ``~/.config/ocdskingfisher-views/logging.json`` file. To download the default configuration::

    curl https://raw.githubusercontent.com/open-contracting/kingfisher-views/master/samples/logging.json -o ~/.config/ocdskingfisher-views/logging.json

To download a different configuration that includes debug messages::

    curl https://raw.githubusercontent.com/open-contracting/kingfisher-views/master/samples/logging-debug.json -o ~/.config/ocdskingfisher-views/logging.json

Read more about :doc:`logging`.

.. _database-connection-settings:

Database connection settings
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Open the configuration file (``~/.config/ocdskingfisher-views/config.ini``), and configure the database connection settings to point to the database used by `Kingfisher Process <https://kingfisher-process.readthedocs.io/en/latest/config.html#postgresql>`__:

.. code-block:: ini

   [DBHOST]
   HOSTNAME = localhost
   PORT = 5432
   USERNAME = ocdskingfisher
   PASSWORD =
   DBNAME = ocdskingfisher

If you prefer not to store the password in ``config.ini``, you can use the `PostgreSQL Password File <https://www.postgresql.org/docs/11/libpq-pgpass.html>`__, ``~/.pgpass``, which overrides any password in ``config.ini``.

.. note::

   You can override the settings in ``config.ini`` (and ``.pgpass``) by setting a ``KINGFISHER_VIEWS_DB_URI`` environment variable. You might want to do this in order to temporarily use a different database than the configured database. For example:

   .. code-block:: bash

      export KINGFISHER_VIEWS_DB_URI='postgresql://user:password@localhost:5432/dbname'

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
