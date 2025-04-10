Querying data
=============

Before you begin, read the :doc:`index` page to learn about how data is stored in Kingfisher Summarize.

Tables in Kingfisher Summarize can contain summaries of:

* individual OCDS releases
* individual OCDS releases from an OCDS record
* compiled OCDS releases generated by Kingfisher Process
* compiled OCDS releases published as part of an OCDS record

Since most analysis is much easier to perform on compiled releases, we recommend working with compiled releases to begin with.

List all schemas in the database
--------------------------------

Kingfisher Summarize creates database schemas to store summary data.

The following query returns a list of schemas in the database:

.. code-block:: sql

  SELECT
    schema_name
  FROM
    information_schema.schemata;

Set the schema to query
-----------------------

The following query sets the ``summary_collection_1257_1259`` schema as the first item in the search path:

.. code-block:: sql

  SET
    search_path
  TO
    summary_collection_1257_1259, public;

.. note::

  Depending on the tool you use to query the database, you might need to run the above query before each other query.

List the collections in the current schema
------------------------------------------

The following query lists the collections in the current schema, with the name of the data source and the type of data summarized:

.. code-block:: sql

  SELECT DISTINCT
      collection_id,
      source_id,
      release_type
  FROM
      release_summary
  ORDER BY
      collection_id DESC;

The ``release_type`` column indicates the type of data stored in the collection:

* ``release`` identifies individual releases
* ``compiled_release`` identifies compiled releases generated by Kingfisher Process
* ``record`` identifies compiled releases published as part of an OCDS record

Get a top-level summary of contracting processes
------------------------------------------------

Top-level summary data is stored in the ``release_summary`` table.

Use one of the ``collection_id`` values returned by the previous query to filter your results to a single collection. To get summaries of individual releases, use a ``release`` collection. To get summaries of entire contracting processes, use a ``compiled_release`` or ``record`` collection.

The following query returns a top-level summary of the first 3 contracting processes in collection ``1259``, which is a ``compiled_release`` collection.

.. code-block:: sql

  SELECT
      *
  FROM
      release_summary
  WHERE
      collection_id = 1259
  LIMIT 3;

To learn more about the summaries and aggregates in the ``release_summary`` table, refer to the :ref:`release_summary` documentation.

To get data from a different collection, change the ``collection_id`` condition.

Calculate the total value of tenders in a collection
----------------------------------------------------

Summary data about tenders is stored in the ``tender_summary`` table.

The following query calculates the total value of tenders disaggregated by currency and tender status in collection ``1259``.

.. code-block:: sql

  SELECT
    value_currency, -- return the currency of the tender value, values in OCDS have an amount and a currency, as datasets may contain values in multiple currencies
    status,
    sum(value_amount)
  FROM
    tender_summary
  WHERE
    collection_id = 1259
  GROUP BY
    value_currency,
    status
  ORDER BY
    value_currency,
    status;

To learn more about the summaries and aggregates in the ``tender_summary`` table, refer to the :ref:`tender_summary` documentation.

.. tip::

  The ``tender``, ``awards`` and ``contracts`` objects in OCDS all have a ``.status`` field.

  Kingfisher Summarize stores these status fields in the ``tender_summary.status``, ``awards_summary.status`` and ``contracts_summary.status`` columns.

  Consider which statuses you want to include or exclude from your analysis; for example, you might want to exclude pending and cancelled contracts when calculating the total value of contracts for each buyer.

  The `OCDS codelist documentation <https://standard.open-contracting.org/latest/en/schema/codelists/#>`__ describes the meaning of the statuses for each object.

Calculate the top 10 buyers by award value
------------------------------------------

Summary data about buyers is stored in the ``buyer_summary`` table, and summary data about awards is stored in the ``award_summary`` table.

To join summary tables, use the ``id`` column, which uniquely identifies a release. To learn more about the relationships between tables, refer to the :ref:`erd` documentation.

The ``buyer_summary`` table doesn't include the buyer's name; however, the ``buyer`` column contains a JSONB blob of the buyer for each contracting process, from which the buyer's name can be queried.

Most summary tables include a column that contains a JSONB blob of the object to which the summary relates. For example, the ``award`` column in ``awards_summary`` and the ``tender`` column in ``tender_summary``.

The following query calculates the top 10 buyers by award value for collection ``1259``, disaggregated by currency, and counting 'active' awards only:

.. code-block:: sql

  SELECT
      buyer_id,
      buyer -> 'name' AS buyer_name, -- extract the buyer name from the JSON
      value_currency,
      sum(value_amount) AS award_amount
  FROM
      awards_summary
  JOIN
      buyer_summary ON awards_summary.id = buyer_summary.id
  WHERE
      awards_summary.collection_id = 1259
  AND
      awards_summary.value_amount > 0 -- filter out awards with no value
  AND
      awards_summary.status = 'active'
  GROUP BY
      buyer_id,
      buyer_name,
      value_currency
  ORDER BY
      award_amount DESC
  LIMIT 10;

Check which fields are available
--------------------------------

Use the `OCDS schema documentation <https://standard.open-contracting.org/latest/en/schema/release/>`__ to understand the meaning, structure and format of the fields in OCDS and to identify the fields needed for your analysis.

Coverage of the OCDS schema varies by publisher. Use the ``field_counts`` table to check whether the fields needed for your analysis are available.

The following query lists the coverage of each field in the current schema:

.. code-block:: sql

  SELECT
    *
  FROM
    field_counts;

For schemas with multiple collections, use the ``collection_id`` column to filter your results for a particular collection.

You can also check the coverage of specific fields or groups of fields by filtering on the ``path`` column:

.. code-block:: sql

  SELECT
    *
  FROM
    field_counts
  WHERE
    path IN ('tender/value/amount', 'tender/procurementMethod');
