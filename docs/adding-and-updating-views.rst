Adding and updating views
=========================

Important prerequisites for adding and updating views are familiarity with SQL and the `Open Contracting Data Standard <ocds-standard-development-handbook.readthedocs.io/>`__. You don't need to know Python as there is no need to touch the Kingfisher Views source code, only the SQL queries. 

.. _before:

Before you start
----------------

Before you're ready to modify any of the views, you need to:

1. Set up an appropriate :ref:`development environment<devenv>`.
2. Make and checkout a new git branch for your changes.
3. :ref:`Load some data<loadingdata>`. The changes you want to make should be applicable to some data you have, or be supported by our `test data <https://github.com/open-contracting/kingfisher-views/tree/master/tests/fixtures>`__ so that you can easily try out your changes and make sure they work.
4. Find your way :ref:`around the SQL files<sql-contents>`.

Workflow overview
------------------

The subsequent sections will walk you through the details of adding or updating views. A general overview of the process you will follow is:

1. Get Kingfisher Views up and running locally (see: :ref:`before you start<before>`).
2. Modify the SQL file(s) as needed.
3. :ref:`Run your changes and review<testing-changes>` the new or updated views.
4. Update the :ref:`documentation<adding-docs>`.
5. Run the tests.
6. If you want your changes to be included in the main Kingfisher Views software, :ref:`push your branch to github and make a pull request<deploy>`.

Example: adding a field
-----------------------

In this example we're going to add a field to the `tender` and `awards` views. We know from familiarity with the OCDS that `tender` and `award` objects both have :code:`description` fields at their top level, so we would like to see these in the respective views.

1. First, find the query to modify:
  * We can find the `tender` views in the :code:`005-tender.sql` file.
  * The main `tender` view is assembled first in the :code:`staged_tender_summary` table.

2. Add the new field to the select query.
  * You can see the other top level fields in the query, so add it alongside those: 

.. code-block:: sql

    create table staged_tender_summary
    AS
    select
        r.id,
        r.release_type,
        r.collection_id,
        r.ocid,
        r.release_id,
        r.data_id,
        tender ->> 'id' AS tender_id,
        tender ->> 'title' AS tender_title,
        tender ->> 'status' AS tender_status,
        tender ->> 'description' AS tender_description, -- This is our addition
    ...

3. We can do the same for `awards`, using the :code:`006-awards.sql` file and the :code:`staged_awards_summary_no_data` table:

.. code-block:: sql
    
    ...
    award ->> 'title' AS award_title,
    award ->> 'status' AS award_status,
    award ->> 'description' AS award_description, -- This is ours
    ...

4. Now :ref:`test your changes<testing-changes>`.

5. Then :ref:`add documentation<adding-docs>`. This is **required**!

6. Run the tests to make sure your changes were successful and you didn't break anything else in the process by running: :code:`pytest`

Example: adding an aggregate
----------------------------

This example demonstrates how Kingfisher Views uses layers of queries and intermediary (:code:`tmp`) tables to build up the final views. In the OCDS data model, various objects can have an array of `documents` attached to them. We're going to add an aggregate (the total number of `documents`) for the planning object.

1. We're going to be updating the `release summary` views, so we need the :code:`008-release.sql` file.
  * Queries are in blocks beginning with :code:`drop table if exists` up to :code:`create unique index`.
  * Queries are grouped together roughly by the stages in the planning process, but there are no hard and fast rules. When you're adding new queries, just try to find a place for them that might make logical sense for the next person who comes along to edit this file - which may well be you.

2. We need to add document counts for `planning` and `tender` objects. They already exist for `award` and `contract`, and the structure is the same, so we can copy one of the existing queries and change the field names, eg:

.. code-block:: sql

    -- We add all of this, copying from tmp_award_documents_aggregates

    drop table if exists tmp_planning_documents_aggregates;
    create table tmp_planning_documents_aggregates
    AS
    select 
        id, 
        jsonb_object_agg(coalesce(documentType, ''), documentType_count) planning_documentType_counts
    from
        (select 
            id, documentType, count(*) documentType_count
        from
            planning_documents_summary
        group by
            id, documentType
        ) AS d
    group by id;

    create unique index tmp_planning_documents_aggregates_id on tmp_planning_documents_aggregates(id);

3. Next we need to see where the intermediary :code:`tmp_` tables are used, and add our new table in there as well. Later in the file are joins which connect the aggregates to the summary table. The order of the joins is the order the columns appear in the table, so place new ones according to how you want to see the output:

.. code-block:: sql

    -- We add this with the rest of the joins in the file
    left join
        (select id, documents_count AS total_planning_documents from planning_summary) AS planning_summary using(id) 
    left join
        tmp_planning_documents_aggregates
    using(id)

4. Finally we drop the :code:`tmp_` table since we don't need it any more:

.. code-block:: sql

    drop table if exists tmp_planning_documents_aggregates;

5. Now :ref:`test your changes<testing-changes>`.

6. Then :ref:`add documentation<adding-docs>`. This is **required**!

7. Run the tests to make sure your changes were successful and you didn't break anything else in the process by running: :code:`pytest`

.. _testing-changes:

Testing your changes
--------------------

Test your update by comparing it to the initial view you made when :ref:`loading data<loadingdata>`.

  * Either create a new view: :code:`python ocdskingfisher-views-cli add-view 1 "Test: view with descriptions" --name "{collection_name_changed}"`
  * or refresh your existing view: :code:`python ocdskingfisher-views-cli refresh-views {collection_name}`
  * Verify that the data is what you expect it to be.
  * (If you're looking at the data in a postgres client, don't forget to refresh it.)

.. _adding-docs:

Adding documentation
--------------------

The tests won't pass if you don't document new fields!

1. Add changes to the inline field-level documentation as follows:
  * Edit the :code:`999-docs.sql` file to add the new fields and their descriptions as comments on columns. The comments should be in the same order as the tables.
  * Eg. for the examples above:

.. code-block:: sql

    -- For the new field on tender:

    Comment on column %%1$s.tender_id IS '`id` from `tender` object';
    Comment on column %%1$s.tender_title IS '`title` from `tender` object';
    Comment on column %%1$s.tender_status IS '`status` from `tender` object';
    Comment on column %%1$s.tender_description IS '`description` from `tender` object'; -- This is our update
    ...
    -- For the planning document aggregates:

    'Comment on column %%1$s.total_planning_documents IS ''Count of planning documents in this release''; '
    'Comment on column %%1$s.planning_documenttype_counts IS ''JSONB object with the keys as unique planning/documents/documentType and the values as count of the appearances of those documentTypes''; '

2. Test your documentation additions.
  * Run :code:`refresh-views`, which will throw an error if you've made a typo.
  * Preview the docs in your postgres client by looking at the schema to check the new comment appears.

3. Update the CSV files of the docs by running :code:`python ocdskingfisher-views-cli docs-table-ref {collection_name}`
  * If there is additional documentation about the fields in certain views, eg. notes for yourself or colleagues, this is a good time to update that as well.

.. _deploy:

Making your changes live
------------------------

You may be planning only to use your new views locally. In which case, you're all done!

But if you want to make your changes available to others, or to have them deployed on the hosted Kingfisher server, you shoud:

1. Make a `pull request <https://github.com/open-contracting/kingfisher-views/pull/>`__ on to `Kingfisher Views on github <https://github.com/open-contracting/kingfisher-views>`__
2. Request review from one of the core development team. Github will probably suggest some sensible names to you.
3. Merge the approved changes into master.
4. And to update hosted Kingfisher Views, ask a developer to deploy it to the server for you.

If you want to update the existing views data on the server, you will need to run :code:`refresh-views` on everything on the server.
