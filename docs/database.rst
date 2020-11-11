Database tables reference
=========================

Introduction
------------

How tables are created
~~~~~~~~~~~~~~~~~~~~~~

The :ref:`add` command creates all the tables below.

How values are extracted
~~~~~~~~~~~~~~~~~~~~~~~~

Most values are extracted from OCDS JSON as SQL text. This is the case even if the JSON value is of a different type; for example, if the value of an ``id`` field is serialized as a JSON integer, it will be stored as text in the SQL tables.

There are two cases in which other types are used:

* Date fields are converted to the ``timestamp`` type.  **Warning:** If the value is an invalid date like ``"2020-02-30"``, or if the year is less than or equal to ``0000``, it will be converted to ``NULL``.
* Number fields are converted to the ``numeric`` type.  **Warning:** If the value is an invalid number like ``"123a"``, it will be converted to ``NULL``.

.. _relationships:

How tables are related
~~~~~~~~~~~~~~~~~~~~~~

Each summary table has an ``id`` column and a ``release_type`` column. The ``id`` column in a summary table refers to the ``id`` column in the ``release_summary_no_data`` table. For a given ``id`` value, the ``release_type`` value is the same in all tables (in other words, the ``release_type`` column is `denormalized <https://en.wikipedia.org/wiki/Denormalization>`__).

The ``table_id`` column in the ``release_summary_no_data`` table refers to the ``id`` column in either Kingfisher Process' ``release``, ``record`` or ``compiled_release`` table. If the ``release_type`` is "embedded_release", the referred table is the ``record`` table. Otherwise, the referred table matches the value of the ``release_type`` column (either "release", "record" or "compiled_release").

If the ``release_type`` is "record", then the record's ``compiledRelease`` field is used to generate summaries. If the ``release_type`` is "embedded_release", then the record's ``releases`` array is used to generate summaries.

Foreign key relationships exist on all `tables <https://www.postgresql.org/docs/current/sql-createtable.html>`__ (but not `views <https://www.postgresql.org/docs/current/sql-createview.html>`__) within a schema, as shown in the Entity Relationship Diagram below (click on the image and zoom in to read more easily).

.. image:: _static/erd.png
   :target: _static/erd.png

This diagram can help to identify JOIN conditions. For example, all tables can be joined with the ``release_summary_no_data`` and ``release_summary`` tables on the ``id`` column.

Some tables have composite foreign keys. These are shown as two lines from one table to another in the diagram. To join such tables:

.. code-block:: sql

   SELECT *
   FROM awards_document_summary
   JOIN awards_summary
     ON awards_summary.id = awards_document_summary.id AND
        awards_summary.award_index = awards_document_summary.award_index

Or, more briefly:

.. code-block:: bash

   SELECT *
   FROM awards_document_summary
   JOIN awards_summary USING (id, award_index)

.. _metadata:

Metadata
--------

These tables are created and populated by the :ref:`add` command.

selected_collections
~~~~~~~~~~~~~~~~~~~~

This table contains the collection IDs that the user provided when creating the schema.

If you need to change the collections to be summarized, remove the schema with the :ref:`remove` command and re-create it with the :ref:`add` command. This ensures that the schema's name reflects its contents.

.. csv-table::
   :header-rows: 1
   :widths: 10, 10, 40
   :file: definitions/selected_collections.csv

note
~~~~

This table contains the note that the user provided when creating the schema.

.. csv-table::
   :header-rows: 1
   :widths: 10, 10, 40
   :file: definitions/note.csv

.. _fields:

Fields
------

.. _field-counts-table:

field_counts
~~~~~~~~~~~~

.. csv-table::
   :header-rows: 1
   :widths: 10, 10, 40
   :file: definitions/field_counts.csv

.. _db-releases:

Releases
--------

.. _release_summary:

release_summary
~~~~~~~~~~~~~~~

.. csv-table::
   :header-rows: 1
   :widths: 10, 10, 40
   :file: definitions/release_summary.csv

release_summary_no_data
~~~~~~~~~~~~~~~~~~~~~~~

.. csv-table::
   :header-rows: 1
   :widths: 10, 10, 40
   :file: definitions/release_summary_no_data.csv

.. _db-parties:

Parties
-------

parties_summary
~~~~~~~~~~~~~~~

.. csv-table::
   :header-rows: 1
   :widths: 10, 10, 40
   :file: definitions/parties_summary.csv

buyer_summary
~~~~~~~~~~~~~

.. csv-table::
   :header-rows: 1
   :widths: 10, 10, 40
   :file: definitions/buyer_summary.csv

procuringEntity_summary
~~~~~~~~~~~~~~~~~~~~~~~

.. csv-table::
   :header-rows: 1
   :widths: 10, 10, 40
   :file: definitions/procuringEntity_summary.csv

tenderers_summary
~~~~~~~~~~~~~~~~~

.. csv-table::
   :header-rows: 1
   :widths: 10, 10, 40
   :file: definitions/tenderers_summary.csv

.. _db-planning:

Planning section
----------------

planning_summary
~~~~~~~~~~~~~~~~

.. csv-table::
   :header-rows: 1
   :widths: 10, 10, 40
   :file: definitions/planning_summary.csv

planning_documents_summary
~~~~~~~~~~~~~~~~~~~~~~~~~~

.. csv-table::
   :header-rows: 1
   :widths: 10, 10, 40
   :file: definitions/planning_documents_summary.csv

planning_milestones_summary
~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. csv-table::
   :header-rows: 1
   :widths: 10, 10, 40
   :file: definitions/planning_milestones_summary.csv

.. _db-tender:

Tender section
--------------

.. _tender_summary:

tender_summary
~~~~~~~~~~~~~~

.. csv-table::
   :header-rows: 1
   :widths: 10, 10, 40
   :file: definitions/tender_summary.csv

tender_summary_no_data
~~~~~~~~~~~~~~~~~~~~~~

.. csv-table::
   :header-rows: 1
   :widths: 10, 10, 40
   :file: definitions/tender_summary_no-data.csv

tender_items_summary
~~~~~~~~~~~~~~~~~~~~

.. csv-table::
   :header-rows: 1
   :widths: 10, 10, 40
   :file: definitions/tender_items_summary.csv

tender_documents_summary
~~~~~~~~~~~~~~~~~~~~~~~~

.. csv-table::
   :header-rows: 1
   :widths: 10, 10, 40
   :file: definitions/tender_documents_summary.csv

tender_milestones_summary
~~~~~~~~~~~~~~~~~~~~~~~~~

.. csv-table::
   :header-rows: 1
   :widths: 10, 10, 40
   :file: definitions/tender_milestones_summary.csv

.. _db-awards:

Awards section
--------------

.. _awards_summary:

awards_summary
~~~~~~~~~~~~~~

.. csv-table::
   :header-rows: 1
   :widths: 10, 10, 40
   :file: definitions/awards_summary.csv

award_suppliers_summary
~~~~~~~~~~~~~~~~~~~~~~~

.. csv-table::
   :header-rows: 1
   :widths: 10, 10, 40
   :file: definitions/award_suppliers_summary.csv

award_items_summary
~~~~~~~~~~~~~~~~~~~

.. csv-table::
   :header-rows: 1
   :widths: 10, 10, 40
   :file: definitions/award_items_summary.csv

award_documents_summary
~~~~~~~~~~~~~~~~~~~~~~~

.. csv-table::
   :header-rows: 1
   :widths: 10, 10, 40
   :file: definitions/award_documents_summary.csv

.. _db-contracts:

Contracts section
-----------------

contracts_summary
~~~~~~~~~~~~~~~~~

.. csv-table::
   :header-rows: 1
   :widths: 10, 10, 40
   :file: definitions/contracts_summary.csv

contract_items_summary
~~~~~~~~~~~~~~~~~~~~~~

.. csv-table::
   :header-rows: 1
   :widths: 10, 10, 40
   :file: definitions/contract_items_summary.csv

contract_documents_summary
~~~~~~~~~~~~~~~~~~~~~~~~~~

.. csv-table::
   :header-rows: 1
   :widths: 10, 10, 40
   :file: definitions/contract_documents_summary.csv

contract_milestones_summary
~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. csv-table::
   :header-rows: 1
   :widths: 10, 10, 40
   :file: definitions/contract_milestones_summary.csv

.. _db-contract-implementation:

Contract implementation section
-------------------------------

contract_implementation_transactions_summary
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. csv-table::
   :header-rows: 1
   :widths: 10, 10, 40
   :file: definitions/contract_implementation_transactions_summary.csv

contract_implementation_documents_summary
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. csv-table::
   :header-rows: 1
   :widths: 10, 10, 40
   :file: definitions/contract_implementation_documents_summary.csv

contract_implementation_milestones_summary
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. csv-table::
   :header-rows: 1
   :widths: 10, 10, 40
   :file: definitions/contract_implementation_milestones_summary.csv
