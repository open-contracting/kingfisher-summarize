Reset Database
==============

This command will remove all the base tables from the views schema this can only be done if the all the views have also been to deleted.
So, to reset the whole of the view schema:

.. code-block:: shell-session

    python ocdskingfisher-views-cli refresh-views --remove
    python ocdskingfisher-views-cli reset-database
