Setup
=====

These commands are used to setup and upgrade Kingfisher Views.

.. _alembic-upgrade:

Alembic upgrade
---------------

Creates and/or updates Kingfisher Views' configuration tables:

.. code-block:: bash

   alembic --raiseerr --config ocdskingfisherviews/alembic.ini upgrade head

The tables are:

``views.alembic_version``
   The version number of the database configuration, managed by `Alembic <https://alembic.sqlalchemy.org/>`__
``views.mapping_sheets``
   A copy of the OCDS `release schema <https://standard.open-contracting.org/latest/en/schema/release/>`__ in `tabular format <https://github.com/open-contracting/kingfisher-views/blob/master/ocdskingfisherviews/migrations/versions/1-1-3.csv>`__
``views.read_only_user``
   See the :ref:`correct-user-permissions` command

.. _upgrade-app:

Upgrade Kingfisher Views
~~~~~~~~~~~~~~~~~~~~~~~~

You must run the above command whenever you update Kingfisher Views' source code.

If the new version of Kingfisher Views makes changes to SQL statements, you might want to re-create the collection-specific schemas. For each schema, run the :ref:`refresh-views`, :ref:`field-counts` and :ref:`correct-user-permissions` commands, in that order.
