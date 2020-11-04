Edit SQL files
==============

You should be familiar with SQL and the `Open Contracting Data Standard <ocds-standard-development-handbook.readthedocs.io/>`__. You don't need to know Python, as there's no need to touch Kingfisher Views' Python files, only its SQL files.

This how-to guide will walk you through the steps of editing SQL files (if you haven't already, please follow the :doc:`setup` guide):

#. Make your changes to the SQL files
#. :ref:`Review your changes<review-changes>`
#. :ref:`Update the documentation<add-docs>`
#. Run the tests, to make sure your changes were successful and didn't break anything else.

   .. code-block:: bash

      pytest

#. :ref:`Format the SQL files<format-sql>`
#. To merge your changes into Kingfisher Views, :ref:`push your changes to GitHub and make a pull request<merge>`

Make changes
------------

Example: Add a column
~~~~~~~~~~~~~~~~~~~~~

We want to add the ``description`` values of the ``Tender`` and ``Award`` objects to the :ref:`relevant<db-tender>` :ref:`tables<db-awards>` in Kingfisher Views.

#. Find the SQL table to change.

   -  The tables summarizing the ``Tender`` object are in the ``005-tender.sql`` file.
   -  The ``tender_summary_no_data`` table is the SQL table to change.

#. Add the ``description`` field to the ``SELECT`` clause for the ``tender_summary_no_data`` table.

   -  You can see the other OCDS fields in the statement. Add it alongside those:

   .. code-block:: sql

       CREATE TABLE tender_summary_no_data AS
       SELECT
           r.id,
           r.release_type,
           r.collection_id,
           r.ocid,
           r.release_id,
           r.data_id,
           tender ->> 'id' AS tender_id,
           tender ->> 'title' AS tender_title,
           tender ->> 'status' AS tender_status,
           tender ->> 'description' AS tender_description, -- OUR ADDITION
       ...

#. Do the same for the table summarizing the ``Award`` object.

   -  The tables summarizing the ``Award`` objects are in the ``006-awards.sql`` file.
   -  Edit the ``SELECT`` clause for the ``awards_summary_no_data`` table.

   .. code-block:: sql

       ...
       award ->> 'title' AS award_title,
       award ->> 'status' AS award_status,
       award ->> 'description' AS award_description, -- OUR ADDITION
       ...

Example: Add an aggregate
~~~~~~~~~~~~~~~~~~~~~~~~~

We want to add the number of ``Document`` objects (in total and for each ``documentType`` value) across all ``Planning`` objects to the :ref:`relevant table<db-releases>` in Kingfisher Views.

This example demonstrates how Kingfisher Views uses temporary (``tmp_*``) tables to build its final tables.

#. Find the :ref:`block<sql-contents>` of SQL statements to use as a template for adding the aggregate.

   -  The ``award_documentType_counts`` and ``contract_documentType_counts`` columns already exist for ``Award`` and ``Contract`` objects.
   -  Try to find a place to add the new block that will make sense for the next person who edits the file.

   .. code-block:: sql

       -- Add this before the tmp_award_documents_aggregates block, using that block as a template.

       CREATE TABLE tmp_planning_documents_aggregates AS
       SELECT
           id,
           jsonb_object_agg(coalesce(documentType, ''), documentType_count) planning_documentType_counts
       FROM
           (SELECT
               id,
               documentType,
               count(*) documentType_count
           FROM
               planning_documents_summary
           GROUP BY
               id, documentType) AS d
       GROUP BY
           id;

       CREATE UNIQUE INDEX tmp_planning_documents_aggregates_id ON tmp_planning_documents_aggregates(id);

#. Do the same for the total documents.

   -  The ``total_award_documents`` and ``total_contract_documents`` columns already exist for ``Award`` and ``Contract`` objects.
   -  An OCDS release has only one ``Planning`` object, so we remove the ``sum()`` function and ``group by`` clause.

   .. code-block:: sql

      -- Add this before the tmp_release_awards_aggregates block, using that block as a template.

      CREATE TABLE tmp_release_planning_aggregates AS
      SELECT
          id,
          documents_count AS total_planning_documents
      FROM
          planning_summary;

      CREATE UNIQUE INDEX tmp_release_planning_aggregates_id ON tmp_release_planning_aggregates(id);

#. Find the SQL table to change.

   -  The tables summarizing the entire collection are in the ``008-release.sql`` file.
   -  The ``release_summary`` table is created by ``JOIN`` ing many ``tmp_*`` tables.

#. Add ``JOIN`` s for the new blocks.

   -  The order of the ``JOIN`` s controls the order of the columns in the table.

   .. code-block:: sql

      -- Add this before the tmp_release_awards_aggregates JOIN.

      LEFT JOIN tmp_release_planning_aggregates USING (id)
      LEFT JOIN tmp_planning_documents_aggregates USING (id)

#. Drop our ``tmp_`` tables:

   .. code-block:: sql

      -- Add this before `DROP TABLE tmp_release_awards_aggregates;`

      DROP TABLE tmp_release_planning_aggregates;
      DROP TABLE tmp_planning_documents_aggregates;

.. _review-changes:

Review changes
--------------

Review your changes by comparing to the initial summaries you created when :ref:`loading data<load-data>`. Create new summaries:

.. code-block:: bash

   python ocdskingfisher-views-cli add-view 1 "Review new column" --name review_new_column

Then, check that the data is as you expect it to be. (If you're viewing the data in a PostgreSQL client, don't forget to refresh it.)

.. _add-docs:

Update documentation
--------------------

The tests won't pass if you don't document the new columns!

#. Edit the ``999-docs.sql`` file to add comments on the new columns:

   -  The comments should be in the same order as the corresponding columns in the tables. You can use other comments for similar columns as a template.

   .. code-block:: sql

      -- For the "Add a column" example

      ...
      COMMENT ON COLUMN %1$s.tender_id IS '`id` from `tender` object';
      COMMENT ON COLUMN %1$s.tender_title IS '`title` from `tender` object';
      COMMENT ON COLUMN %1$s.tender_status IS '`status` from `tender` object';
      COMMENT ON COLUMN %1$s.tender_description IS '`description` from `tender` object'; -- OUR ADDITION
      ...

      -- For the "Add an aggregate" example

      COMMENT ON COLUMN %1$s.total_planning_documents IS 'Count of planning documents in this release';
      COMMENT ON COLUMN %1$s.planning_documenttype_counts IS 'JSONB object with the keys as unique planning/documents/documentType and the values as count of the appearances of those documentTypes';

#. Run the ``999-docs.sql`` file (:ref:`refresh-views` throws an error if you made a typo above) (replacing ``COLLECTION_NAME`` below):

   .. code-block:: bash

      python ocdskingfisher-views-cli refresh-views COLLECTION_NAME

#. Review your changes.

   -  In your PostgreSQL client, Look at relevant tables' schemas to check that new comments appear.

#. :ref:`Update the documentation files<docs-files>` (replacing ``COLLECTION_NAME`` below):

  .. code-block:: bash

     python ocdskingfisher-views-cli docs-table-ref COLLECTION_NAME

.. _format-sql:

Format SQL files
----------------

We use `pg_format <https://github.com/darold/pgFormatter>`__ to consistently format SQL files. On macOS, using `Homebrew <https://brew.sh>`__, install it with:

.. code-block:: bash

   brew install pgformatter

Then, run:

.. code-block:: bash

   find sql -maxdepth 1 -name '*.sql' -exec pg_format -f 1 -p '%1\$s' -o {} {} \;

.. _merge:

Merge your changes
------------------

If your changes are for your own use only, you're done!

If you want to share your changes with others:

#. Create a new branch in your git repository and commit your changes:

   .. code-block:: bash

      git checkout -b my-changes
      git commit -a -m 'Add X column to Y table'

#. Push the changes to GitHub:

   .. code-block:: bash

      git push -u origin my-changes

#. Follow the link in the output to create a pull request for `Kingfisher Views <https://github.com/open-contracting/kingfisher-views>`__. The maintainers will assign your pull request for review, and merge it as appropriate.

To apply your changes to existing schema created by Kingfisher Views, see :ref:`upgrade-app`.
