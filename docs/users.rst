Read-Only Users
===============

This how-to guide describes how to:

-  Add a user
-  Grant a user read-only access to all tables in all schemas created by Kingfisher Views
-  Remove a user

Add a user
----------

#. Connect to the ``postgres`` database as the ``postgres`` user. For example, as a sudoer, run:

   .. code-block:: bash

      sudo -u postgres psql

#. Create the user. For example, replace ``the-username`` with a recognizable username (for example, the lowercase name of the person to whom you are giving access, like ``janedoe``) and ``the-password`` with a `strong password <https://www.lastpass.com/password-generator>`__, and run:

   .. code-block:: sql

      CREATE USER the-username WITH PASSWORD 'the-password';

#. Close your PostgreSQL session and your sudo session.

Grant a user read-only access
-----------------------------

#. Connect to the database used by Kingfisher Views, using the connecting settings you :ref:`configured earlier<database-connection-settings>`. For example, run:

   .. code-block:: bash

      psql ocdskingfisher -U ocdskingfisher

#. Insert the username into the ``view_meta.read_only_user`` table. For example, replace ``the-username``, and run:

   .. code-block:: sql

      INSERT INTO view_meta.read_only_user VALUES ('the-username');

#. Close your PostgreSQL session.

#. Run the :doc:`cli/correct-user-permissions` command to grant the user read-only access to all tables in all schemas created by Kingfisher Views:

   .. code-block:: bash

      python ocdskingfisher-views-cli correct-user-permissions

Remove a user
-------------

#. Connect to the database used by Kingfisher Views, using the connecting settings you :ref:`configured earlier<database-connection-settings>`. For example, run:

   .. code-block:: bash

      psql ocdskingfisher -U ocdskingfisher

#. Delete the username from the ``view_meta.read_only_user`` table. For example, replace ``the-username``, and run:

   .. code-block:: sql

      DELETE FROM view_meta.read_only_user WHERE username = 'the-username';

#. Drop the user. For example, replace ``the-username``, and run:

   .. code-block:: sql

      DROP USER the-username;

#. Close your PostgreSQL session.
