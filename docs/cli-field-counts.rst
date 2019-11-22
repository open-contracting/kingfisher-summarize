Command line tool - Field Counts
===========================================

This tool will update the ``field_count`` table.

.. code-block:: shell-session

    python ocdskingfisher-views-cli field-counts

To remove the table run:

.. code-block:: shell-session

    python ocdskingfisher-views-cli field-counts --remove


In order to make it run you faster you can define how many threads it runs with.

.. code-block:: shell-session

    python ocdskingfisher-views-cli field-counts --threads 5


By default, the command will run on the main "views" schema. If you have added extra views, and want it to run on those, pass the name as an option:

.. code-block:: shell-session

    python ocdskingfisher-views-cli field-counts --viewname test1
