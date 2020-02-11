Read Only Users
===============

View supports the creation of read only users that have access to all views and the main process database.

Adding
------

To create a new user, firstly create the user as a Postgresql user yourself.

On a Ubuntu Linux server, after connecting as root this would probably look like:

.. code-block:: bash

    # su postgres
    $ psql template1

Generate a strong password using `passwordsgenerator.net <https://passwordsgenerator.net/>`__ or similiar.

.. code-block:: sql

    CREATE USER testreadonly with PASSWORD 'insert-strong-password-here' NOCREATEDB NOSUPERUSER NOCREATEROLE;

Then go to the normal views database, using the normal username, password and other settings you use to access that. Put the new username in as an entry in the ``read_only_user`` table in the ``view_meta`` schema.

.. code-block:: sql

    SET search_path = view_meta;
    INSERT INTO read_only_user (username) VALUES ('testreadonly');


Then run the :doc:`cli-correct-user-permissions` command - this will actually set the correct user permissions.

Note the database user the :doc:`cli-correct-user-permissions` command connects as must be the owner of the database for this to work - but that is true of the views app generally.

Removing
--------

Go to the database, and the ``view_meta`` schema, and the ``read_only_user`` table.
Remove the username as a entry in that table.

At this point, the user will still have access.

Now remove the actual user.


.. code-block:: sql

    DROP USER testreadonly;
