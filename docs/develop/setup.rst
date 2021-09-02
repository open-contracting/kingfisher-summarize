Setup
=====

Follow the :doc:`../get-started` guide.

.. _load-data:

Load data
---------

To test your changes, you need to have some data loaded. The `test data <https://github.com/open-contracting/kingfisher-summarize/tree/main/tests/fixtures>`__ covers common fields, but you might have specific data that you want to test against.

#. Load test data, as created by Kingfisher Process:

   .. code-block:: bash

      pg_restore tests/fixtures/kingfisher-process.sql

#. Change to Kingfisher Summarize's directory, and activate its virtual environment. Then, summarize collection 1:

   .. code-block:: bash

      ./manage.py add 1 "some note"

#. Look at the data that has been created, so you have something to compare against when you make changes.

   -  Select from tables in the ``view_data_collection_1`` schema
   -  Select from the view ``release_summary``
