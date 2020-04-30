Logging
=======

If logging is configured using a :ref:`default configuration<config-logging>`, then log messages are written to ``info.log`` (and possibily ``debug.log``).

Log messages are formatted as::

    %(asctime)s - %(process)d - %(name)s - %(levelname)s - %(message)s

You can find the meaning of the ``%(…)s`` attributes in the `Python documentation <https://docs.python.org/3/library/logging.html#logrecord-attributes>`__.

In particular, you can use the ``name`` attribute to filter messages by topic. For example:

.. code-block:: bash

    grep NAME info.log | less

where ``NAME`` is one of:

ocdskingfisher.views.add-view
  ``INFO``-level messages for the process of adding a view.
ocdskingfisher.views.config
  An ``WARN``-level message if there was a problem loading the config.
ocdskingfisher.views.field-counts
  ``INFO``-level for the process of running field counts.
ocdskingfisher.views.refresh-views
  ``INFO``-level for the process of running refresh views.
ocdskingfisher.views.cli
  An ``INFO``-level message whenever a CLI command is run, by a user or by `cron <https://en.wikipedia.org/wiki/Cron>`__.
ocdskingfisher.views.cli.delete-view
  ``INFO``-level for the process of deleting a view.
