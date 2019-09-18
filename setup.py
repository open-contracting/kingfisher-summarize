from setuptools import setup, find_packages

with open('README.md') as f:
    long_description = f.read()

setup(
    name='ocdskingfisher-views',
    version='0.0.1',
    author='Open Contracting Partnership, Open Data Services, Iniciativa Latinoamericana para los Datos Abiertos',
    author_email='data@open-contracting.org',
    url='https://github.com/open-contracting/kingfisher-views',
    description='A set of PostgreSQL views for OCDS Kingfisher',
    license='BSD',
    packages=find_packages(exclude=['tests', 'tests.*']),
    long_description=long_description,
    long_description_content_type='text/markdown',
    install_requires=[
        'alembic',
        'logzero',
        'pgpasslib',
        'psycopg2',
    ],
    extras_require={
        'test': [
            'coveralls',
            'pytest',
            'pytest-cov',
        ],
    },
    package_data={'ocdskingfisher': [
        'migrations/script.py.mako'
    ]},
    include_package_data=True,
    classifiers=[
        'License :: OSI Approved :: BSD License',
        'Programming Language :: Python :: 3.6',
    ],
    scripts=[
        'ocdskingfisher-views-cli',
    ],
)
