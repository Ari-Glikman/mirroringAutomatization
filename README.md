# mirroring Automatization (between containers)

this is a script that automates the mirroring steps in iris for health environments
particularly, this is to mirror a database as well as a foundation namespace

to call this script: ./hello.sh <directory of primary database> <name of database to mirror> <directory of secondary database> <foundation namespace name>

NOTE: THIS IS DONE BETWEEN TWO DOCKER CONTAINERS. MIRRORING MUST BE ENABLED BEFOREHAND AND THE CONTAINERS CONNECTED (VIA A NETWORK OF SOME SORT)

NOTE: THE NAMES OF THE CONTAINERS ARE HARDCODED (THIS CAN BE CHANGED EASILY), THEY ARE: mirror-a (primary), mirror-b (secondary)
