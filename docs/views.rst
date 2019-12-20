Views
=====

This tool can create many Views, or Schemas, in your database. Each view can be built from a seperate set of data.

Views
-----

You can create views. Each one is in it's own Postgres schema and can contain data for 1 or more collections - you specify the exact ID's when creating the view.

The build process for each view can happen totally independently from other views, and thus it can be triggered as soon as a collection is ready.

Use the :doc:`cli-add-view`  command to add a view.

This may take a long time, and you may want to run it via ``tmux`` or similar.


Querying
--------

Views can be found in the postgres schema ``view_data_ + the name you set`` within ocdskingfisher database.

.. code-block:: postgresql

    select * from view_data_test.release_summary;

Alternatively you can run

.. code-block:: postgresql

    set search_path = view_data_test, public;

at the start of your sql script meaning that Postgres will first look at the ``view_data_test`` schema then at kingfisher-process (which lives in the ``public`` schema) so that you can just do:

.. code-block:: postgresql

    select * from release_summary 



Structure
---------

The set of tables that end with ``_summary`` all have key named ``id``.

This ``id`` represents either a release, compiled_release (compiled by kingfisher) or record, and is unique across these types. There is ``release_type`` in the tables to say what type it is.

For a record the ``compiledRelease`` within it is used in the summary tables.



Changing and rerunning views after creation
-------------------------------------------

Every schema has a ``selected_collections`` table. After a view has been created, you can still change what collections it contains by editing the contents of this table directly.

After you have done this, you will need to rebuild the view.

(You may also want to rebuild an existing view if this software has been updated, and you want your view to have the results of the new build process.)

To do this, run the :doc:`cli-refresh-views` then the :doc:`cli-field-counts` command on your view. This may take a long time, and you may want to run it via ``tmux`` or similar.


Checking notes in a view
------------------------

When you create a view, you can specify a note.

You can see all notes attached to a view when running the :doc:`cli-list-views` command.

(You can also look in the schema for a particular view, and just look in the contents of the ``note`` table.)

Deleting a view
---------------

Finally, please delete views when you have finished with them to save disk space. Use the :doc:`cli-delete-view` command.


