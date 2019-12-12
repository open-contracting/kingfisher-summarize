Command line tool - Field Counts
===========================================

This tool will update the ``field_count`` table.

.. code-block:: shell-session

    python ocdskingfisher-views-cli field-counts viewname

You must pass the view name.

To remove the table run:

.. code-block:: shell-session

    python ocdskingfisher-views-cli field-counts viewname --remove


In order to make it run you faster you can define how many threads it runs with.

.. code-block:: shell-session

    python ocdskingfisher-views-cli field-counts viewname --threads 5

