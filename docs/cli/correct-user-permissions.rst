correct-user-permissions
========================

To setup correct user permissions for all specified users to all schemas, run:

.. code-block:: shell-session

   python ocdskingfisher-views-cli correct-user-permissions

Note this command can only correct user permissions on tables that have already been created when the command is run.

If you then run a command that might create new tables (for example, :doc:`refresh-views` or :doc:`field-counts`) you may need to run this command again.
