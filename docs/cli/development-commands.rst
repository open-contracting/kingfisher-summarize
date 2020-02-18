Development Commands
====================

``docs/reference/database.rst`` displays the CSV files in the ``docs/reference/definitions/`` directory. To create and/or update the CSV files, run:

.. code-block:: bash

   python ocdskingfisher-views-cli docs-table-ref

Then, for each new CSV file, add a new sub-section to ``docs/reference/database.rst`` under an appropriate section.

To generate an Alembic migration to upgrade the base tables run:

.. code-block:: bash

   python ocdskingfisher-views-cli make-migration
