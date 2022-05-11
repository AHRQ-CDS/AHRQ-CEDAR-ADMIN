# Changelog

## upcoming

* Retains metadata for artifacts deleted by a repository

## v0.4.0

* Changes "retired" status to "archived" on artifacts
* Updates importers to capture strength of evidence information where available
* Updates search logs to separate code searches into supported code systems
* Fixes importer bug where whitespace was not being appropriately stripped

## v0.3.2

* Fixes issue with links in keyword tag cloud

## v0.3.1

* Fixes bug where certain concept searches were not displayed correctly in search log
* Updates dates and times to all use a common representation

## v0.3.0

* Fixes bug with import of UMLS concepts where concept descriptions were not included in list of synonyms
* Improves granularity and robustness of database backups
* Implements LDAP-based authentication
* Makes it easier to navigate to results of individual importer runs
* Improves robustness of import process when errors are encountered
* Updates EHC importer to match EHC CMS and data feed changes
* Adds suitable default artifact type and status for SRDR importer

## v0.2.0

* Adds keyword support to SRDR importer
* Adds support for full repository name
* Improves metadata extraction in importers
* Improves escaping of query characters
* Updates ruby version

## v0.1.1

* Minor updates to headers and link generation

## v0.1.0

* Initial version of CEDAR Admin
