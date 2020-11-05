Setup
=====

These commands are used to setup Kingfisher Views.

.. _install:

install
-------

Creates Kingfisher Views' configuration tables:

.. code-block:: bash

   python ocdskingfisher-views-cli install

The tables are:

``views.mapping_sheets``
   A copy of the OCDS `release schema <https://standard.open-contracting.org/latest/en/schema/release/>`__ in `tabular format <https://github.com/open-contracting/kingfisher-views/blob/master/ocdskingfisherviews/1-1-3.csv>`__
``views.read_only_user``
   See the :ref:`correct-user-permissions` command
