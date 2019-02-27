#!/usr/bin/env python
import io
import os
from distutils.core import setup


here = os.path.abspath(os.path.dirname(__file__))

# Import the README and use it as the long-description.
with io.open(os.path.join(here, 'README.md'), encoding='utf-8') as f:
    long_description = '\n' + f.read()

setup(name='ocdskingfisher-views',
      version='0.0.1',
      description='A set of views of ocdskingfisher',
      long_description=long_description,
      long_description_content_type='text/markdown',
      author='Open Contracting Partnership, Open Data Services, Iniciativa Latinoamericana para los Datos Abiertos',
      author_email='data@open-contracting.org',
      url='https://open-contracting.org',
      license='BSD',
      packages=[
            'ocdskingfisherviews',
            'ocdskingfisherviews.cli',
            'ocdskingfisherviews.cli.commands',
            'ocdskingfisherviews.migrations',
            'ocdskingfisherviews.migrations.versions',
      ],
      scripts=['ocdskingfisher-views-cli'],
      package_data={'ocdskingfisher': [
              'migrations/script.py.mako'
          ]},
      include_package_data=True
      )
