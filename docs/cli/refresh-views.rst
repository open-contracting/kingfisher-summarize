Refresh Views
=============

This tool will refresh all the views in the views schema.

.. code-block:: shell-session

   python ocdskingfisher-views-cli refresh-views viewname

You must pass the view name.

To remove all the tables run:

.. code-block:: shell-session

   python ocdskingfisher-views-cli refresh-views viewname --remove

It has several options to make modifying the views easier to work with.

The SQL scripts can be found in the ``sql`` directory of the repository and the all begin with a number.

You can set the start and end number (inclusive) of the SQL scripts that you want to run.

.. code-block:: shell-session

   python ocdskingfisher-views-cli refresh-views viewname --start 4 --end 5

This will run scripts ``004-planning.sql`` and ``005-tender.sql``. Without ``--start`` the scripts will run from the start and without ``--end`` they will run to the end```

If you want to see the output of what SQL will be run without actually executing it then run:

.. code-block:: shell-session

   python ocdskingfisher-views-cli refresh-views viewname --sql

