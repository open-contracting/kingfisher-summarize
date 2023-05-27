Changelog
=========

2023-06-01
----------

Added
~~~~~

-  Add a ``--filter-sql-json-path`` option to the :ref:`add` command.

Changed
~~~~~~~

-  Change schema prefix from ``view_data_`` to ``summary_``.
-  Upgrade to Python 3.10 and PostgreSQL 15.

2023-05-27
----------

Added
~~~~~

-  ``KINGFISHER_SUMMARIZE_LOGGING_JSON`` environment variable
-  ``dev hash-md5`` command

2021-12-21
----------

Changed
~~~~~~~

-  The ``field_list`` column is now a JSONB object in which keys are paths and values are numbers of occurrences (instead of ``NULL``).

2021-11-24
----------

Added
~~~~~

- Add a ``--filter`` option to the :ref:`add` command.

2021-11-02
----------

Added
~~~~~

-  Add a ``relatedprocesses_summary`` table.

2021-09-15
----------

Changed
~~~~~~~

-  Replace the ``selected_collections`` table in individual schema with a ``selected_collections`` table in the ``summaries`` schema.

2021-08-10
----------

Fixed
~~~~~

-  Fix support for :ref:`release types<relationships>` of "embedded_release" and "record".

2021-07-29
----------

Changed
~~~~~~~

-  Replace similar tables with templated queries. This does not affect behavior.

2021-07-16
----------

Added
~~~~~

-  Add a ``name`` column to the ``parties_summary``, ``procuringentity_summary``, ``tenderers_summary`` and ``award_suppliers_summary`` tables.

Changed
~~~~~~~

-  Rename ``parties_id`` columns to:

   -  ``parties_summary.party_id``
   -  ``buyer_summary.buyer_id``
   -  ``procuringentity_summary.procuringentity_id``
   -  ``tenderers_summary.tenderer_id``

-  Rename document ``documentType`` counts:

   -  ``documenttype_counts`` to ``document_documenttype_counts``
   -  ``planning_documenttype_counts`` to ``planning_document_documenttype_counts``
   -  ``tender_documenttype_counts`` to ``tender_document_documenttype_counts``
   -  ``award_documenttype_counts`` to ``award_document_documenttype_counts``
   -  ``contract_documenttype_counts`` to ``contract_document_documenttype_counts``
   -  ``contract_implementation_documenttype_counts`` to ``contract_implementation_document_documenttype_counts``
   -  ``implementation_documenttype_counts`` to ``implementation_document_documenttype_counts``

-  Rename milestone ``type`` counts:

   -  ``milestonetype_counts`` to ``milestone_type_counts``
   -  ``contract_milestonetype_counts`` to ``contract_milestone_type_counts``
   -  ``contract_implementation_milestonetype_counts`` to ``contract_implementation_milestone_type_counts``
   -  ``implementation_milestonetype_counts`` to ``implementation_milestone_type_counts``

2021-07-08
----------

Changed
~~~~~~~

-  Rename ``total_documenttype_counts`` to ``documenttype_counts``.
-  Rename ``additionalidentifiers_ids`` to ``additionalclassifications_ids`` on ``*_items_summary`` tables

Fixed
~~~~~

-  ``unique_identifier_attempt`` uses party fields instead of deprecated fields.

2021-06-30
----------

Changed
~~~~~~~

-  Columns are `renamed <https://docs.google.com/spreadsheets/d/1UdPZXmiuir_mFQDYJHTWbwgdWnORzMTlbKUEsspxK54/edit#gid=855843256>`__ for consistency.

2021-05-21
----------

Added
~~~~~

-  ``dev stale`` command
-  ``--quiet`` option

2021-02-25
----------

Changed
~~~~~~~

-  Move ``docs-table-ref`` command under ``dev`` group.
-  ``add`` command: ``--skip`` developer's option to skip SQL files.

2021-02-01
----------

Changed
~~~~~~~

-  ``add`` command: Errors if ``--name`` value contains uppercase characters.
-  Fix typo in ``contract_implemetation_documenttype_counts`` column (missing "n").

2021-01-06
----------

Changed
~~~~~~~

-  Remove ``install`` command
-  Remove ``correct-user-permissions`` command
-  Remove ``views`` schema, including ``views.read_only_user`` and ``views.mapping_sheets`` tables
-  Remove ``flatten_with_values`` SQL function

2020-12-11
----------

Changed
~~~~~~~

-  The ``field_list`` column is now a JSONB object in which keys are paths and values are ``NULL``


2020-12-09
----------

Added
~~~~~

-  ``add`` command: ``--field-lists`` option to add a ``field_list`` column to all summary tables. The ``field-list`` column is an array of all fields in the data.
-  ``planning_summary`` table: A ``planning`` JSONB column for the planning object.
-  ``contract_implementation_transactions_summary`` table:  A ``transaction`` JSONB column for the transaction object.

2020-11-11
----------

Changed
~~~~~~~

-  Rename ``ocdskingfisher-views-cli`` to ``manage.py``.
-  Rename commands:

   -  ``list-views`` to ``index``
   -  ``add-view`` to ``add``
   -  ``delete-view`` to ``remove``

-  Configure the database connection using a ``KINGFISHER_SUMMARIZE_DATABASE_URL`` environment variable or ``.env`` file, instead of a ``KINGFISHER_VIEWS_DB_URI`` environment variable or ``config.ini`` file.

2020-11-05
----------

Added
~~~~~

-  ``add-view`` command: Add ``--no-field-counts`` option.

Changed
~~~~~~~

-  ``add-view`` command: Remove ``--threads`` option.
-  Remove ``refresh-views`` command.
-  Remove ``field-counts`` command.
-  Improve performance.
