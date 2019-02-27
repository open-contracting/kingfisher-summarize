Views
=====

Views can be found in the postgres schema `views` within ocdskingfisher database.  
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



