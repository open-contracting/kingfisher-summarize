Views
=====

This tool can create many Views, or Schemas, in your database. Each view can be built from a seperate set of data.

The Default View
----------------

By default, a view is created called ``views``.

This is a special one, in that the collections it has data for consist of the latest version of each collection in the process database.
It also includes any extra collections you add to ``extra_collections`` table in ``views`` schema.

Extra Views
-----------

You can create extra views. Each one is in it's own Postgres schema and can contain data for 1 or more collections - you specify the exact ID's when creating the view.

The build process for extra views can happen totally independently for the build process for the default views, and thus it can be triggered as soon as a collection is ready.

Use the :doc:`cli-add-view`  command to add a view.

This may take a long time, and you may want to run it via ``tmux`` or similar.


Querying
--------


Views can be found in the postgres schema `views` within ocdskingfisher database
(or the schema  ``view_data_ + the name you set``).
In order to use them you can prefix the view with schema.

.. code-block:: postgresql

    select * from views.release_summary;

Alternatively you can run

.. code-block:: postgresql

    set search_path = views, public;

at the start of your sql script meaning that posgres will first look at the `views` schema then at kingfisher-process (which lives in the public schema) so that you can just do:

.. code-block:: postgresql

    select * from release_summary 



Structure
---------

The set of tables that end with "_summary" all have key named ``id``.

This ``id`` represents either a release, compiled_release (compiled by kingfisher) or record, and is unique across these types. There is ``release_type`` in the tables to say what type it is.

For a record the ``compiledRelease`` within it is used in the summary tables.



Changing and rerunning Extra Views after creation
-------------------------------------------------

Every schema has a ``selected_collections`` table. After a view has been created, you can still change what collections it contains by editing the contents of this table directly.

After you have done this, you will need to rebuild the view.

(You may also want to rebuild an existing view if this software has been updated, and you want your view to have the results of the new build process.)

To do this, run the :doc:`cli-refresh-views` then the :doc:`cli-field-counts` command on your view. This may take a long time, and you may want to run it via ``tmux`` or similar.


