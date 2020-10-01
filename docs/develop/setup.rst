Setup
=====

Prerequisites
-------------

You can either :doc:`install all requirements manually<../get-started>` or `use the preconfigured Vagrant setup <https://kingfisher-vagrant.readthedocs.io/en/latest/>`__.

If using Vagrant, remember to modify Kingfisher Views's SQL files and source code **on your host machine**, not in the Vagrant environment. See also how to `access the database <https://kingfisher-vagrant.readthedocs.io/en/latest/#working-with-the-database>`__ in Vagrant.

.. _load-data:

Load data
---------

To test your changes, you need to have some data loaded. The `test data <https://github.com/open-contracting/kingfisher-views/tree/master/tests/fixtures>`__ covers common fields, but you might have specific data that you want to test against.

#. Set up Kingfisher Process' database, create a collection, and load the test data into it (replacing ``COLLECTION_NAME`` below):

   .. code-block:: bash

      (vagrant) cd /vagrant/process
      (vagrant) source .ve/bin/activate
      (vagrant) python ocdskingfisher-process-cli upgrade-database
      (vagrant) python ocdskingfisher-process-cli new-collection COLLECTION_NAME '2000-01-01 00:00:00'
      (vagrant) python ocdskingfisher-process-cli local-load 1 ../views/tests/fixtures release_package
      (vagrant) deactivate

#. Summarize collection 1 using Kingfisher Views:

   .. code-block:: bash

      (vagrant) cd /vagrant/views
      (vagrant) source .ve/bin/activate
      (vagrant) python ocdskingfisher-views-cli add-view 1 "some note"

#. Look at the data that has been created, so you have something to compare against when you make changes.

   -  Select from tables in the ``view_data_collection_1`` schema
   -  Select from the view ``release_summary``
