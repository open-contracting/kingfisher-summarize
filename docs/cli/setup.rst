Setup
=====

.. _install:

install
-------

Creates Kingfisher Summarize's configuration tables:

.. code-block:: bash

   ./manage.py install

The tables are:

``views.mapping_sheets``
   A copy of the OCDS `release schema <https://standard.open-contracting.org/latest/en/schema/release/>`__ in `tabular format <https://github.com/open-contracting/kingfisher-summarize/blob/master/ocdskingfishersummarize/1-1-3.csv>`__
``views.read_only_user``
   See the :ref:`correct-user-permissions` command
