Contributing
============

First, follow the :doc:`setup` guide, and read this page. Then, learn how to :doc:`sql` or follow the :doc:`howtos`.

.. _sql-files:

SQL files
---------

The SQL statements that summarize data are stored in SQL files in the `sql/middle directory <https://github.com/open-contracting/kingfisher-summarize/tree/master/sql/middle>`__. The :ref:`add` command runs these SQL files.

The dependencies between SQL files are automatically determined. Files should create one table and/or view and related indices, and should not drop tables. Instead, any temporary tables should be dropped in ``sql/final/drop.sql``.

SQL files are named after the tables they create, though some files don't match table names:

``*_tmp.sql``
  For example, the ``tmp_planning_summary`` table is created in the ``planning_tmp.sql`` file, so that it appears next to files that create :ref:`planning<db-planning>` tables.
``parties_*_summary.sql``
  For example, the ``buyer_summary`` table is created in the ``parties_buyer_summary.sql`` file, so that it appears next to other files that create :ref:`parties<db-parties>` tables.
``agg_*.sql``
  For example, the ``tmp_planning_documents_aggregates`` table is created in the ``agg_planning.sql`` file, so that it appears next to other files that create temporary aggregates.

.. toctree::
   :maxdepth: 2
   :caption: Contents

   setup
   howtos
   sql
