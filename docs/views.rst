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

First, use the ``add-view`` command to add a view.

Secondly, look at the ``selected_collections`` table in the new view you just created. It will be under the schema ``view_data_ + the name you set``.

Add to this table the ID's of the collections you want in this view.

Then use the :doc:`cli-refresh-views`  and :doc:`cli-field-counts` to update data in the view. In both cases pass the optional view name parameter.

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



