#!/bin/bash
#set -e
source func.sh
prereqtest

path=$(dirname $1)

cfg.parser $1
cfg.section.main
cfg.section.config

#todo test every required configuration

if [ -z "$id" ]; then
        id=$(pvesh get /cluster/nextid)
	else
	if isidtaken $id ; 
		then
		echo "$id is taken"
		exit 2
	fi
fi

downloadimage ${cloudimage}
originalimage=$(basename $cloudimageurl)
customimage=custom_$(basename ${cloudimage})
cp ${originalimage} ${customimage}


#qemu-img resize ${customimage} ${disksize}
custommotd ${customimage} "This VM was built from template ${id}.\nThe original image used to create the template was ${cloudimage}.\nThe template was built $(date), with version string ${version}.\nBogdan Dumitru\n------------------------\n\n\n"

if [ ! -z ${firstbootscript} ]; then

	if [ ! -f ${firstbootscript} ]; then
		firstbootscript=${path}/${firstbootscript}
	fi

	setfirstbootscript ${customimage} ${firstbootscript}

fi

if [ ! -f ${commands} ]; then
	commands=${path}/${commands}
fi

runcommands ${customimage} ${commands}

if [ ! -f ${packages} ]; then
	packages=${path}/${packages}
fi

installpackages ${customimage} ${packages}
truncatemachineid ${customimage}  

if [ ! -f ${publickeyfile} ]; then
	publickeyfile=${path}/${publickeyfile}
fi

deployvm ${storagepool} ${customimage} ${id} ${disksize} ${name} ${networkbridge} ${user} ${publickeyfile}

if [ X${astemplate} == X"true" ]; 
then
 	templatevm ${id}
	else
	if [ ! -z ${ipconfig} ]; then
        	qm set $id --ipconfig0 ip="${ipconfig}"
	fi
fi


