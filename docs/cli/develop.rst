Develop
=======

These commands are used to author Kingfisher Views.

make-migration
--------------

Creates a generic `Alembic <https://alembic.sqlalchemy.org/>`__ migration file in the `ocdskingfisherviews/migrations/versions/ <https://github.com/open-contracting/kingfisher-views/tree/master/ocdskingfisherviews/migrations/versions>`__ directory. Replace ``MESSAGE`` with a brief description of what the migration does, and run:

.. code-block:: bash

   python ocdskingfisher-views-cli make-migration 'MESSAGE'

docs-table-ref
--------------

``docs/database.rst`` displays the CSV files in the `docs/definitions/ <https://github.com/open-contracting/kingfisher-views/tree/master/docs/definitions>`__ directory. To create and/or update the CSV files, run:

.. code-block:: bash

   python ocdskingfisher-views-cli docs-table-ref

Then, for any new CSV file, manually add a new sub-section to ``docs/database.rst`` under an appropriate section.

reset-database
--------------

Removes Kingfisher Views' configuration tables:

.. code-block:: bash

   python ocdskingfisher-views-cli reset-database

See :ref:`refresh-views` and :ref:`field-counts` to remove collection-specific schemas.
