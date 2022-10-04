# Changelog

## v0.6.0 - 2022-10-03

* Addresses error when displaying logs for searches that do not complete
* Removes redundant synonym expansions
* Addresses styling issue with menu display
* Updates the EPC importer
    - Identifies archived artifacts using a HTML meta tag
    - Improves support for EPC artifact dates
    - Removes duplicate warnings for missing artifact dates
    - Re-orders import log view so latest import is at the top of the page
* USPSTF importer updates
    - Uses general recommendation pubDate instead of topicYear
    - Adds general recommendation topicType to CEDAR keywords
    - Uses tool keywords to supplement those on the associated general recommendation
* Marks artifacts as retracted after two weeks of failed import attempts
* Suports pruning of older database backups
* Fixes an issue where concepts may only have a Spanish MeSH code
* Updates README with additional information

## v0.5.0 - 2022-07-05

* Retains metadata for artifacts deleted by a repository
* Updates LDAP implementation to be configured via environment variables
* Updates logging to record search result counts by repository
* Supports configuring time of import via environment variable
* Enhances UMLS concept importer
* Fixes an issue with SRDR links
* Improves handling of LDAP errors
* Supports lookup of UMLS description for groups of stored codes in code searches
* Addresses security scan findings
    - Ensures cookies are marked as secure
    - Adds CSP header frame-ancestors 'self'
* Implements changes to support accessibility compliance
* Adds contribution guide, code of conduct and terms and conditions
* Updates styles to reflect AHRQ visual design
* Supports display of link clicks in search log listing
* Improves USPSTF importer to propagate keywords to specific recommendations and tools
* Supports recording of precision of artifact published-on dates
* Updates USPSTF importer to handle re-use of artifact IDs for different artifacts

## v0.4.0 - 2022-02-17

* Changes "retired" status to "archived" on artifacts
* Updates importers to capture strength of evidence information where available
* Updates search logs to separate code searches into supported code systems
* Fixes importer bug where whitespace was not being appropriately stripped

## v0.3.2 - 2022-01-13

* Fixes issue with links in keyword tag cloud

## v0.3.1 - 2022-01-07

* Fixes bug where certain concept searches were not displayed correctly in search log
* Updates dates and times to all use a common representation

## v0.3.0 - 2021-12-23

* Fixes bug with import of UMLS concepts where concept descriptions were not included in list of synonyms
* Improves granularity and robustness of database backups
* Implements LDAP-based authentication
* Makes it easier to navigate to results of individual importer runs
* Improves robustness of import process when errors are encountered
* Updates EHC importer to match EHC CMS and data feed changes
* Adds suitable default artifact type and status for SRDR importer

## v0.2.0 - 2021-11-03

* Adds keyword support to SRDR importer
* Adds support for full repository name
* Improves metadata extraction in importers
* Improves escaping of query characters
* Updates ruby version

## v0.1.1 - 2021-10-15

* Minor updates to headers and link generation

## v0.1.0 - 2021-10-14

* Initial version of CEDAR Admin
