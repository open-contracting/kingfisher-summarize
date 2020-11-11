Changelog
=========

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
