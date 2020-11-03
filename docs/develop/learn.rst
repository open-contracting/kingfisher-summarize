Orientation
===========

SQL files
---------

The SQL statements that summarize data are stored in a sequence of SQL files in the `sql directory <https://github.com/open-contracting/kingfisher-views/tree/master/sql>`__. The :ref:`refresh-views` command runs these SQL files.

For brevity, the SQL files are referred here by their numeric prefix.

Dependencies
~~~~~~~~~~~~

-  All SQL files depend on ``001``, which creates SQL functions.
-  All SQL files depend on ``002``, which creates ``tmp_release_summary``.
-  ``007`` depends on ``006`` (contract summaries need to know about award summaries).
-  ``008`` depends on all SQL files (release summaries need to know about all others).
-  ``008`` drops ``tmp_release_summary``.

.. _sql-contents:

Contents
~~~~~~~~

SQL files are named after the sections of the OCDS data that they summarize. The ``008-release.sql`` file summarizes the entire collection(s).

SQL statements are typically grouped into blocks. A block typically starts with ``DROP TABLE IF EXISTS`` and ends with ``CREATE UNIQUE INDEX``. Make sure to copy-paste the entire block when adding a similar summary.

In ``008-release.sql``, blocks are ordered in roughly the same order as the stages of a contracting process.

In many cases, the final tables are generated from many others. Table names starting with ``tmp_`` are temporary or intermediate tables that are typically dropped at the end of the file in which they are created.

In some cases, ``----`` lines break the files into segments, each of which is executed in a transaction.
