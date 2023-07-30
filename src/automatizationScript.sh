# this is a script that automates the mirroring steps in iris for health environments
# particularly, this is to mirror a database as well as a foundation namespace
# to call this script: ./hello.sh <directory of primary database> <name of database to mirror> <directory of secondary database> <foundation namespace name>
# NOTE: THIS IS DONE BETWEEN TWO DOCKER CONTAINERS. MIRRORING MUST BE ENABLED BEFOREHAND AND THE CONTAINERS CONNECTED (VIA A NETWORK OF SOME SORT)
# NOTE: THE NAMES OF THE CONTAINERS ARE HARDCODED (THIS CAN BE CHANGED EASILY), THEY ARE: mirror-a (primary), mirror-b (secondary)


# ARGS:
# 1: DIRECTORY OF PRIMARY DB 
# 2: NAME OF PRIMARY DB
# 3: DIRECTORY OF BACKUP DB
# 4: NAME OF FOUNDATION NAMESPACE

# first step: schedule task in backup
docker exec -i mirror-b iris session iris -U HSSYS <<MIRROR2
 w "attempting to schedule task"
 zn "HSSYS"
 set st =  ##class(HS.Util.Mirror.Task).Schedule("HSSYS")
 zw st
 halt
MIRROR2

#second step: add database to mirror on primary and dismount off primary (note the commented out part is since we do not want it to create a db here, just trying to mirror hssys)
docker exec -i mirror-a iris session iris -U%SYS <<MIRROR1
write "adding database to primary"
set prop("Directory") = "$1"
set prop("MountAtStartup")=0
set prop("ClusterMountMode")=0
set prop("MountRequired")=0
/// set st=##Class(Config.Databases).Create("$2",.prop)
zw st


set st = ##class(SYS.Mirror).AddDatabase("$1")
zw st

set st = ##class(SYS.Database).DismountDatabase("$1")
zw st

halt
MIRROR1

#third step: dismount database on backup
docker exec -i mirror-b iris session iris -U%SYS <<MIRROR2
 w "attempting to dismount database $3 off backup"
 set st = ##class(SYS.Database).DismountDatabase("$3")
 zw st
 halt
MIRROR2

#fourth step: copy IRIS.DAT from primary to secondary
docker cp mirror-a:$1/IRIS.DAT .
docker cp IRIS.DAT mirror-b:$3

#fifth step: mount database on primary

docker exec -i mirror-a iris session iris -U%SYS <<MIRROR1
write "mounting database $1 to primary"
set st = ##class(SYS.Database).MountDatabase("$1")
zw st

halt
MIRROR1

#sixth step: mount database on backup and catchup
docker exec -i mirror-b iris session iris -U%SYS <<MIRROR2
write "mount database $3 to backup"
set st = ##class(SYS.Database).MountDatabase("$3")
zw st

write "activate database $3 to backup"
set st = ##class(SYS.Mirror).ActivateMirroredDatabase("$3")
zw st


write "catchup database $3 to backup"
set sfns = \$lb(##class(SYS.Database).%OpenId("$3").SFN)
set st = ##class(SYS.Mirror).CatchupDB(sfns,,.errsfns)
zw st

halt
MIRROR2

#seventh step: foundation creation and mirror
docker exec -i mirror-a iris session iris -U HSLIB <<MIRROR1

write "creating mirrored foundation namespace"
set pVars = {}
set pVars("Mirror") = 1

set st = ##class(HS.Util.Installer.Foundation).Install("$4",.pVars)

halt
MIRROR1
