Get started
===========

Prerequisites
-------------

To use Kingfisher Summarize, you need:

-  Access to a `Unix-like shell <https://en.wikipedia.org/wiki/Shell_(computing)>`__ (some are available for Windows)
-  `Git <https://git-scm.com>`__
-  `Python <https://www.python.org/>`__ 3.6 or greater
-  `PostgreSQL <https://www.postgresql.org>`__ 10 or greater
-  `A Kingfisher Process database <https://kingfisher-process.readthedocs.io/en/latest/requirements-install.html>`__

.. _install:

Install
-------

Open a shell, and run:

.. code-block:: bash

   git clone https://github.com/open-contracting/kingfisher-summarize.git
   cd kingfisher-summarize
   pip install -r requirements.txt

All instructions in this documentation assume that you have changed to the ``kingfisher-summarize`` directory (the ``cd`` command above).

.. _configure:

Configure
---------

.. _database-connection-settings:

Database
~~~~~~~~

The database connection is configured by setting the ``KINGFISHER_SUMMARIZE_DATABASE_URL`` environment variable to the `connection URI <https://www.postgresql.org/docs/current/libpq-connect.html#id-1.7.3.8.3.6>`__ of the database used by `Kingfisher Process <https://kingfisher-process.readthedocs.io/en/latest/config.html#postgresql>`__.

It can be set on the command line. For example:

.. code-block:: bash

   export KINGFISHER_SUMMARIZE_DATABASE_URL=postgresql://user:password@localhost:5432/dbname

Or, it can be set in a ``.env`` file in the ``kingfisher-summarize`` directory. For example:

.. code-block:: none

   KINGFISHER_SUMMARIZE_DATABASE_URL=postgresql://user:password@localhost:5432/dbname

If you prefer not to store the password in the ``.env`` file, you can use the `PostgreSQL Password File <https://www.postgresql.org/docs/11/libpq-pgpass.html>`__, ``~/.pgpass``.

The database user must have the `CREATE privilege <https://www.postgresql.org/docs/current/ddl-priv.html>`__ on the database used by Kingfisher Process. For example, for the default database connection settings:

.. code-block:: bash

   psql ocdskingfisher -U ocdskingfisher -c 'GRANT CREATE ON DATABASE ocdskingfisher TO ocdskingfisher;'

.. _config-logging:

Logging
~~~~~~~

.. note::

   This step is optional.

Logging from the :doc:`cli/index` can be configured with a ``logging.json`` file in a `configuration directory <https://click.palletsprojects.com/en/7.x/api/#click.get_app_dir>`__ appropriate to your operating system. Read more about :doc:`logging`.

Setup PostgreSQL database
-------------------------

Create Kingfisher Summarize's configuration tables using the :ref:`install` command:

   .. code-block:: bash

      ./manage.py install

You're now ready to :doc:`use Kingfisher Summarize<cli/use>`.

.. note::

   If you notice slow queries and are using solid-state drives, consider tuning PostgreSQL by decreasing ``random_page_cost``:

   .. code-block:: bash

      ALTER TABLESPACE pg_default SET (random_page_cost = 2.0);
