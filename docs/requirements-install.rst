Requirements and Install
========================

Requirements
------------

Requirements:

- python v3.5 or higher
- Postgresql v10 or higher
- OCDS Kingfisher Database

Installation
------------

Set up a venv and install requirements::

    virtualenv -p python3 .ve
    source .ve/bin/activate
    pip install -e .
    pip install -e git+https://github.com/open-contracting/kingfisher-process.git@master#egg=kingfisherprocess

`Kingfisher Process database needs to be installed. <https://kingfisher-process.readthedocs.io/en/latest/requirements-install.html>`_

A schema called ``views`` need to be set up in the Kingfisher Process database with the same owner as the database. 

Then you need to create the base tables to make the views work see :doc:`cli-upgrade-database`::

   sudo -u postgres psql ocdskingfisher -c 'CREATE SCHEMA views AUTHORIZATION ocdskingfisher' 
   python ocdskingfisher-views-cli upgrade-database

Refreshing the views
--------------------

In order to populat the view use :doc:`cli-refresh-views`.

.. code-block:: shell-session

   python ocdskingfisher-views-cli refresh-views
