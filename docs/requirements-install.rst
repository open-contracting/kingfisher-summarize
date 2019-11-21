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
    pip install -r requirements.txt

`Kingfisher Process database needs to be installed. <https://kingfisher-process.readthedocs.io/en/latest/requirements-install.html>`_


You need to configure the app: :doc:`config`

A schema called ``views`` need to be set up in the Kingfisher Process database with the same owner as the database. 

Then you need to create the base schemas to make the views work see :doc:`cli-upgrade-database`::

   sudo -u postgres psql ocdskingfisher -c 'CREATE SCHEMA views AUTHORIZATION ocdskingfisher' 
   sudo -u postgres psql ocdskingfisher -c 'CREATE SCHEMA view_info AUTHORIZATION ocdskingfisher'
   python ocdskingfisher-views-cli upgrade-database

Refreshing the views
--------------------

In order to populate the view use :doc:`cli-refresh-views`.

.. code-block:: shell-session

   python ocdskingfisher-views-cli refresh-views
