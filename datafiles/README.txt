This directory is used for holding datafiles that need to be loaded
into CEDAR such as "MRCONSO.RRF" and "desc2021.xml". When cedar_admin
is deployed via docker this directory is mounted as a volume, allowing
the import rake task to run inside the docker container and access the
datafiles on the host system.
