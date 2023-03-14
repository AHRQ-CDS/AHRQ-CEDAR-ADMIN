# Changelog

## v0.8.0 - 2023-03-14

* Adds a page that summarizes search statistics
    - Summarizes searches that have taken place over a selectable time period
    - Graphs the number of searches by day over that time period
    - Lists the top IP addresses performing searches over that time period
    - Allows exclusion of one or more IP addresses from the total tally of results
    - Allows clicking on an IP address to see the search logs for that IP address
* Adds feature to display top 10 click thru and top 10 returned artifacts
* Improves visibility of flagged imports and adds page showing complete import history
* Improves parsing of dates when indexing EPC artifacts
* Improves handling of EPC technology assessment artifacts
* Fixes a URL issue with email notifications
* Fixes an efficiency issue with displaying search logs
* Fixes an XML namespace issue when handling NIH bookshelf imports
* Updates USPSTF indexer to stop indexing blocked JAMA Network pages
* Refactors complex SQL queries into database views

## v0.7.2 - 2023-02-22

* Uses NIH bookshelf metadata service for NIH imports instead of scraping HTML
* Fixes an exception handling issue with importer
* Updates to Ruby 3.0.3 and Rails 6.1.7

## v0.7.1 - 2023-01-18

* Temporarily works around importer issue of descriptions being removed from source repository
* Adds more configurability to email settings

## v0.7.0 - 2023-01-05

* Adds feature to detect a large number of changes on import and require approval
* Adds repository descriptions
* Flags external links with icon and adds a popup
* Fixes issue with importing concepts that are empty strings
* Fixes issue where description fields were not always correctly synched
* Adds appropriate user agent on importer requests
* Adds introductory text to site and updates links
* Updates dependencies

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
