Configuration
=============

Setup
-----

Create the tool's configuration directory::

    mkdir ~/.config/ocdskingfisher-views

Download the sample main configuration file::

    curl https://raw.githubusercontent.com/open-contracting/kingfisher-views/master/samples/config.ini -o ~/.config/ocdskingfisher-views/config.ini

Open the main configuration file at ``~/.config/ocdskingfisher-views/config.ini``, and follow the instructions below to update it.

PostgreSQL
----------


Configure the database connection settings - this should point to the same database Kingfisher Process uses:

.. code-block:: ini

   [DBHOST]
   HOSTNAME = localhost
   PORT = 5432
   USERNAME = ocdskingfisher
   PASSWORD =
   DBNAME = ocdskingfisher

If you prefer not to store the password in ``config.ini``, you can use the `PostgreSQL Password File <https://www.postgresql.org/docs/11/libpq-pgpass.html>`__, ``~/.pgpass``, which overrides any password in ``config.ini``.

To override ``config.ini`` and/or ``.pgpass``, set the ``KINGFISHER_VIEWS_DB_URI`` environment variable. This is useful to temporarily use a different database than your default database. For example, in a bash-like shell::

    export KINGFISHER_VIEWS_DB_URI='postgresql://user:password@localhost:5432/dbname'

