Development Commands
====================

To generate the table schema CSV files and generate a schema-reference.rst file run:

.. code-block:: shell-session

   python ocdskingfisher-views-cli docs-table-ref

To generate an alembic migration to upgrade the base tables run:

.. code-block:: shell-session

   python ocdskingfisher-views-cli make-migration
