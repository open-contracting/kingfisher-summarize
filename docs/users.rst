Sharing access
==============

This how-to guide describes how to:

-  Add a user
-  Grant a user read-only access to *some* tables created by Kingfisher Views
-  Grant a user read-only access to *all* tables created by Kingfisher Views and Kingfisher Process
-  Remove a user

Add a user
----------

#. Connect to the ``postgres`` database as the ``postgres`` user. For example, as a sudoer, run:

   .. code-block:: bash

      su - postgres -c psql

#. Create the user. For example, replace ``the_password`` with a `strong password <https://www.lastpass.com/password-generator>`__ and ``the_username`` with a recognizable username (for example, the lowercase name of the person, like ``janedoe``, to whom you want to give access), and run:

   .. code-block:: sql

      CREATE USER the_username WITH PASSWORD 'the_password';

#. Close your PostgreSQL session.

Grant a user read-only access to *some* tables
----------------------------------------------

Connect to the database used by Kingfisher Views, using the connecting settings you :ref:`configured earlier<database-connection-settings>`. For example, run:

   .. code-block:: bash

      psql ocdskingfisher -U ocdskingfisher

To grant access to all tables within a specific schema, run, for example:

.. code-block:: sql

   GRANT USAGE ON SCHEMA view_data_the_name TO the_username;
   GRANT SELECT ON ALL TABLES IN SCHEMA view_data_the_name TO the_username;

Grant a user read-only access to *all* tables
---------------------------------------------

#. Connect to the database used by Kingfisher Views, using the connecting settings you :ref:`configured earlier<database-connection-settings>`.

#. Insert the username into the ``views.read_only_user`` table. For example, replace ``the_username``, and run:

   .. code-block:: sql

      INSERT INTO views.read_only_user VALUES ('the_username');

#. Close your PostgreSQL session.

#. Run the :ref:`correct-user-permissions` command to grant the user read-only access to the tables created by Kingfisher Views and Kingfisher Process:

   .. code-block:: bash

      python ocdskingfisher-views-cli correct-user-permissions

Remove a user
-------------

#. Connect to the database used by Kingfisher Views, using the connecting settings you :ref:`configured earlier<database-connection-settings>`.

#. Delete the username from the ``views.read_only_user`` table. For example, replace ``the_username``, and run:

   .. code-block:: sql

      DELETE FROM views.read_only_user WHERE username = 'the_username';

#. Drop the user. For example, replace ``the_username``, and run:

   .. code-block:: sql

      DROP USER the_username;

#. Close your PostgreSQL session.
