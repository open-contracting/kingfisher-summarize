Read Only Users
===============

View supports the creation of read only users that have access to all views and the main process database.

Adding
------

To create a new user, firstly create the user as a postgres user yourself. Something like:

.. code-block:: sql

    CREATE USER testreadonly with PASSWORD 'k1ngf1sher' NOCREATEDB NOSUPERUSER NOCREATEROLE;

Then go to the database, and the ``view_meta`` schema, and the ``read_only_user`` table.
Put the new username in as a entry in that table.

Then run the :doc:`cli-correct-user-permissions` command - this will actually set the correct user permissions.

Note the user the process connects as must be the owner of the database for this to work.

Removing
--------

Go to the database, and the ``view_meta`` schema, and the ``read_only_user`` table.
Remove the username as a entry in that table.

At this point, the user will still have access.

Now remove the actual user.


.. code-block:: sql

    DROP USER testreadonly;
