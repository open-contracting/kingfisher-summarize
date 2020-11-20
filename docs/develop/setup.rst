Setup
=====

Follow the :doc:`../get-started` guide.

.. _load-data:

Load data
---------

To test your changes, you need to have some data loaded. The `test data <https://github.com/open-contracting/kingfisher-summarize/tree/master/tests/fixtures>`__ covers common fields, but you might have specific data that you want to test against.

#. Change to Kingfisher Process's directory, and activate its virtual environment. Then, set up Kingfisher Process' database, create a collection, and load the test data into it (replacing ``COLLECTION_NAME`` below):

   .. code-block:: bash

      python ocdskingfisher-process-cli upgrade-database
      python ocdskingfisher-process-cli new-collection COLLECTION_NAME '2000-01-01 00:00:00'
      python ocdskingfisher-process-cli local-load 1 ../views/tests/fixtures release_package

#. Change to Kingfisher Summarize's directory, and activate its virtual environment. Then, summarize collection 1:

   .. code-block:: bash

      ./manage.py add 1 "some note"

#. Look at the data that has been created, so you have something to compare against when you make changes.

   -  Select from tables in the ``view_data_collection_1`` schema
   -  Select from the view ``release_summary``
