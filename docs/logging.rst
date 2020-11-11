Reading logs
============

If logging is configured using a :ref:`default configuration<config-logging>`, then log messages are written to ``info.log`` (and possibly ``debug.log``).

Log messages are formatted as::

    %(asctime)s - %(process)d - %(name)s - %(levelname)s - %(message)s

You can find the meaning of the ``%(…)s`` attributes in the `Python documentation <https://docs.python.org/3/library/logging.html#logrecord-attributes>`__.

In particular, you can use the ``name`` attribute to filter messages by topic. For example:

.. code-block:: bash

    grep NAME info.log | less

where ``NAME`` is one of:

ocdskingfisher.summarize.cli
  An ``INFO``-level message whenever a CLI command is run, by a user or by `cron <https://en.wikipedia.org/wiki/Cron>`__.
ocdskingfisher.summarize.add
  An ``INFO``-level message from the add command.
ocdskingfisher.summarize.delete
  An ``INFO``-level message from the delete command.
ocdskingfisher.summarize.field-counts
  An ``INFO``-level message from the field-counts routine.
ocdskingfisher.summarize.install
  An ``INFO``-level message from the install command.
ocdskingfisher.summarize.summary-tables
  An ``INFO``-level message from the summary-tables routine.
