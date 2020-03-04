Use
===

These commands are used to create and manage the :doc:`summary tables<../database>` of one or more collections.

.. _add-view:

add-view
--------

Creates a schema containing :doc:`summary tables<../database>` about one or more collections.

Unless you set the ``--dontbuild`` flag, then this command will effectively call the following commands in this order:

#. :ref:`refresh-views`
#. :ref:`field-counts`
#. :ref:`correct-user-permissions`

This command will fail if the schema already exists.

.. summarize-one-collection:

Summarize one collection
~~~~~~~~~~~~~~~~~~~~~~~~

Replace ``ID`` with a Kingfisher Process collection ID, replace ``NOTE`` with your name and a description of your purpose, and run:

.. code-block:: bash

   python ocdskingfisher-views-cli add-view ID "NOTE"

For example:

.. code-block:: bash

   python ocdskingfisher-views-cli add-view 123 "Created by Morgan A. to measure procurement indicators"

This creates a schema named ``view_data_collection_123``.

.. _set-schema-name:

Customize the schema's name
^^^^^^^^^^^^^^^^^^^^^^^^^^^

To customize the last part of the schema's name (for example, ``collection_123`` in ``view_data_collection_123``), set the ``--name`` argument to `a string of letters, numbers and/or underscores <https://www.postgresql.org/docs/current/sql-syntax-lexical.html#SQL-SYNTAX-IDENTIFIERS>`__. For example:

.. code-block:: bash

    python ocdskingfisher-views-cli add-view 123 "The note" --name the_name

This creates a schema named ``view_data_the_name``.

.. _summarize-many-collections:

Summarize many collections
~~~~~~~~~~~~~~~~~~~~~~~~~~

Instead of passing one collection ID, you can pass many collection IDs, separated by commas. For example:

.. code-block:: bash

   python ocdskingfisher-views-cli add-view 4,5,6 "Created by Morgan A. to compare field coverage"

This creates a schema named ``view_data_collection_4_5_6``.

If you need to summarize more than five collections, then you must :ref:`customize the schema's name<set-schema-name>`.

.. _delete-view:

delete-view
-----------

Drops a schema.

Replace ``NAME`` with the last part of a schema's name (the part after ``view_data_``), and run:

.. code-block:: bash

   python ocdskingfisher-views-cli delete-view NAME

This is equivalent to:

.. code-block:: sql

  DROP SCHEMA view_data_NAME CASCADE;

.. _list-views:

list-views
----------

Lists the schemas, with collection IDs and creator's notes.

.. code-block:: bash

   python ocdskingfisher-views-cli list-views

Outputs:

.. code-block:: none

   -----
   VIEW: collection_4_5_6
   Collection Id: 4
   Collection Id: 5
   Collection Id: 6
   Note: Created by Morgan A. to compare field coverage (2020-01-02 03:04:05.123456)
   -----
   VIEW: collection_123
   Collection Id: 1
   Note: Created by Morgan A. to measure procurement indicators (2020-01-02 03:04:05.123456)

To list the schemas only, Connect to the database used by Kingfisher Views, using the connecting settings you :ref:`configured earlier<database-connection-settings>`, and run:

.. code-block:: none

   \dn

.. _refresh-views:

refresh-views
-------------

.. note::

   You only need to learn this command if you used :ref:`add-view` with ``--dontbuild``, or if you're updating a schema after :ref:`upgrading Kingfisher Views<upgrade-app>`.

Creates (or re-creates) the :doc:`summary tables<../database>`.

Replace ``NAME`` with the last part of a schema's name (the part after ``view_data_``), and run:

.. code-block:: bash

   python ocdskingfisher-views-cli refresh-views NAME

This is equivalent to running the non-downgrade SQL files in the `sql directory <https://github.com/open-contracting/kingfisher-views/tree/master/sql>`__ in numeric order. For example, using the :ref:`default database connection settings<database-connection-settings>`:

.. code-block:: bash

   find sql -type f -not -name '*_downgrade.sql' -print0 | sort -nz | xargs -0 -I{} psql ocdskingfisher -U ocdskingfisher -f '{}'

Remove summary tables
~~~~~~~~~~~~~~~~~~~~~

Set the ``--remove`` flag. For example:

.. code-block:: bash

   python ocdskingfisher-views-cli refresh-views NAME --remove

This is equivalent to running the downgrade SQL files in the `sql directory <https://github.com/open-contracting/kingfisher-views/tree/master/sql>`__ in reverse numeric order. For example, using the :ref:`default database connection settings<database-connection-settings>`:

.. code-block:: bash

   find sql -type f -name '*_downgrade.sql' -print0 | sort -nrz | xargs -0 -I{} psql ocdskingfisher -U ocdskingfisher -f '{}'

.. _field-counts:

field-counts
------------

.. note::

   You only need to learn this command if you used :ref:`add-view` with ``--dontbuild``, or if you're updating a schema after :ref:`upgrading Kingfisher Views<upgrade-app>`.

Creates (or re-creates) the :ref:`field_counts table<field-counts-table>`.

.. warning::

   The :ref:`refresh-views` command must be run before this command.

Replace ``NAME`` with the last part of a schema's name (the part after ``view_data_``), and run:

.. code-block:: bash

   python ocdskingfisher-views-cli field-counts NAME

Improve performance
~~~~~~~~~~~~~~~~~~~

If you are :ref:`summarizing many collections<summarize-many-collections>`, then you can make this command run faster by setting the ``--threads`` argument. For example, if you are summarizing five collections, you can summarize each collection in a parallel thread:

.. code-block:: bash

   python ocdskingfisher-views-cli field-counts NAME --threads 5

There is no advantage to setting the ``--threads`` argument to a number that is greater than the number of collections to summarize.

Every computer has a maximum number of parallel threads. If the ``lscpu`` command is available, multiply its numbers for `Socket(s)`, `Core(s) per socket` and `Thread(s) per core` to get the maximum.

Remove field_counts table
~~~~~~~~~~~~~~~~~~~~~~~~~

Set the ``--remove`` flag. For example:

.. code-block:: bash

   python ocdskingfisher-views-cli field-counts NAME --remove

This is equivalent to:

.. code-block:: sql

  DROP TABLE field_counts;

.. _correct-user-permissions:

correct-user-permissions
------------------------

.. note::

   You only need to learn this command if you used :ref:`add-view` with ``--dontbuild``, if you're updating a schema after :ref:`upgrading Kingfisher Views<upgrade-app>`, or if you are :doc:`sharing access<../users>`.

`Grants <https://www.postgresql.org/docs/current/ddl-priv.html>`__ the users in the ``view_meta.read_only_user`` table the ``USAGE`` privilege on the schemas and the ``SELECT`` privilege on all existing tables in the schemas:

.. code-block:: bash

   python ocdskingfisher-views-cli correct-user-permissions

You must run this command whenever you create (or re-create) schemas or tables. In other words, run this command after using the :ref:`refresh-views` or :ref:`field-counts` command.

The schemas are:

``public``
   Contains all tables created by Kingfisher Process
``views``
   Contains the ``alembic_version`` table
``view_info``
   Contains the ``mapping_sheets`` table
Collection-specific schemas
   Contain the :doc:`summary tables<../database>` about one or more collections, created by the :ref:`add-view`, :ref:`refresh-views` and :ref:`field-counts` commands
