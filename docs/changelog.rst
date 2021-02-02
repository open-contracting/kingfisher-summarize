Changelog
=========

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

-  ``add-view``: Add ``--no-field-counts`` option.

Changed
~~~~~~~

-  ``add-view``: Remove ``--threads`` option.
-  ``refresh-views``: Remove command.
-  ``field-counts``: Remove command.
-  Improve performance.
