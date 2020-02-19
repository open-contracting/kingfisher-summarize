Database tables reference
=========================

Each collection-specific schema contains some or all of the tables below.

Except for the tables in the :ref:`metadata` and :ref:`fields` sections, all tables are created and populated by the :ref:`refresh-views` command (or the :ref:`add-view` command if the ``--dontbuild`` flag isn't set).

.. _metadata:

Metadata
--------

These tables are created and populated by the :ref:`add-view` command.

selected_collections
~~~~~~~~~~~~~~~~~~~~

This table contains the collection IDs that the user provided when creating the schema.

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

These tables are created and populated by the :ref:`field-counts` command (or the :ref:`add-view` command if the ``--dontbuild`` flag isn't set).

.. _field-counts-table:

field_counts
~~~~~~~~~~~~

.. csv-table::
   :header-rows: 1
   :widths: 10, 10, 40
   :file: definitions/field_counts.csv

Releases
--------

These tables are created and populated by ``008-release.sql``.

release_summary
~~~~~~~~~~~~~~~

.. csv-table::
   :header-rows: 1
   :widths: 10, 10, 40
   :file: definitions/release_summary.csv

release_summary_with_data
~~~~~~~~~~~~~~~~~~~~~~~~~

.. csv-table::
   :header-rows: 1
   :widths: 10, 10, 40
   :file: definitions/release_summary_with_data.csv

release_summary_with_checks
~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. csv-table::
   :header-rows: 1
   :widths: 10, 10, 40
   :file: definitions/release_summary_with_checks.csv

Parties
-------

These tables are created and populated by ``003-buyer-procuringentity-tenderer.sql``.

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

Planning section
----------------

These tables are created and populated by ``004-planning.sql``.

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

Tender section
--------------

These tables are created and populated by ``005-tender.sql``.

tender_summary
~~~~~~~~~~~~~~

.. csv-table::
   :header-rows: 1
   :widths: 10, 10, 40
   :file: definitions/tender_summary.csv

tender_summary_with_data
~~~~~~~~~~~~~~~~~~~~~~~~

.. csv-table::
   :header-rows: 1
   :widths: 10, 10, 40
   :file: definitions/tender_summary_with_data.csv

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

Awards section
--------------

These tables are created and populated by ``006-awards.sql``.

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

Contracts section
-----------------

These tables are created and populated by ``007-contracts.sql``.

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

Contract implementation section
-------------------------------

These tables are created and populated by ``007-contracts.sql``.

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
