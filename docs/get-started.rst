Get Started
===========

Prerequisites
-------------

To use Kingfisher Views, you need:

-  `Python <https://www.python.org/>`__ 3.6 or greater
-  `PostgreSQL <https://www.postgresql.org>`__ 10 or greater
-  `An OCDS Kingfisher Process database <https://kingfisher-process.readthedocs.io/en/latest/requirements-install.html>`__

Install Kingfisher Views
------------------------

Open a shell, and run:

.. code-block:: bash

   pip install -r requirements.txt

Configure Kingfisher Views
--------------------------

Create the configuration directory:

.. code-block:: bash

    mkdir ~/.config/ocdskingfisher-views

Download the sample configuration file to the configuration directory:

.. code-block:: bash

    curl -o ~/.config/ocdskingfisher-views/config.ini https://kingfisher-views.readthedocs.io/latest/en/_static/config.ini

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

The database user must have the `CREATE privilege <https://www.postgresql.org/docs/current/ddl-priv.html>`__ on the database used by Kingfisher Process. For example:

.. code-block:: sql

   GRANT CREATE ON DATABASE ocdskingfisher TO ocdskingfisher;

Setup PostgreSQL database
-------------------------

#. Connect to the database as the ``postgres`` user. For example, as a sudoer, run:

   .. code-block:: bash

      sudo -u postgres psql ocdskingfisher

#. `Create <https://www.postgresql.org/docs/current/sql-createschema.html>`__ the ``views``, ``view_info`` and ``view_meta`` schemas, and set them to be owned by the database user configured above. For example, run:

   .. code-block:: sql

      CREATE SCHEMA views AUTHORIZATION ocdskingfisher;
      CREATE SCHEMA view_info AUTHORIZATION ocdskingfisher;
      CREATE SCHEMA view_meta AUTHORIZATION ocdskingfisher;

#. Close your PostgreSQL session and your sudo session.

#. :doc:`Create Kingfisher Views' configuration tables<cli/upgrade-database>`:

   .. code-block:: bash

      python ocdskingfisher-views-cli upgrade-database

.. note::

   The ``views`` schema is only used for the ``alembic_version`` table. The ``view_info`` schema is only used for the ``mapping_sheets`` table. The ``view_meta`` schema is only used for the ``read_only_user`` table.
