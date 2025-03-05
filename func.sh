#!/bin/bash

isaddress(){
local a b c d
{ IFS=. read a b c d; } <<< $1
if [ -z $a ];then
	return 1;
fi
if [ -z $b ]; then
	return 1;
fi
if [ -z $c ]; then
	return 1;
fi
if [ -z $d ]; then
	return 1;
fi
return 0

}

getnextid(){
pvesh get /cluster/nextid
}

isidtaken(){
idtocheck=$1

containerlist=$( pct list | awk '{print $1}' | tail -n +2)

if grep -q $idtocheck <<< $containerlist ; 
      then 
	return
fi

vmlist=$(qm list |  awk '{print $1}' | tail -n +2)
if grep -q $idtocheck <<< $vmlist ; 
	then 
	  return
fi

false;
}

cfg.parser () {
    fixed_file=$(cat $1 | sed 's/ = /=/g')  # fix ' = ' to be '='
    IFS=$'\n' && ini=( $fixed_file )              # convert to line-array
    ini=( ${ini[*]//;*/} )                   # remove comments
    ini=( ${ini[*]/#[/\}$'\n'cfg.section.} ) # set section prefix
    ini=( ${ini[*]/%]/ \(} )                 # convert text2function (1)
    ini=( ${ini[*]/=/=\( } )                 # convert item to array
    ini=( ${ini[*]/%/ \)} )                  # close array parenthesis
    ini=( ${ini[*]/%\( \)/\(\) \{} )         # convert text2function (2)
    ini=( ${ini[*]/%\} \)/\}} )              # remove extra parenthesis
    ini[0]=''                                # remove first element
    ini[${#ini[*]} + 1]='}'                  # add the last brace
    eval "$(echo "${ini[*]}")"               # eval the result
}

ip2int()
{
    local a b c d
    { IFS=. read a b c d; } <<< $1
    echo $(((((((a << 8) | b) << 8) | c) << 8) | d))
}

int2ip()
{
    local ui32=$1; shift
    local ip n
    for n in 1 2 3 4; do
        ip=$((ui32 & 0xff))${ip:+.}$ip
        ui32=$((ui32 >> 8))
    done
    echo $ip
}

netmask()
# Example: netmask 24 => 255.255.255.0
{
    local mask=$((0xffffffff << (32 - $1))); shift
    int2ip $mask
}


broadcast()
# Example: broadcast 192.0.2.0 24 => 192.0.2.255
{
    local addr=$(ip2int $1); shift
    local mask=$((0xffffffff << (32 -$1))); shift
    int2ip $((addr | ~mask))
}

network()
# Example: network 192.0.2.0 24 => 192.0.2.0
{
    local addr=$(ip2int $1); shift
    local mask=$((0xffffffff << (32 -$1))); shift
    int2ip $((addr & mask))
}

pveguestip()
{
IFS=$' \t\n'
proxmoxguest=$1
interface=$2

iplisthost=$(ip -o -4 addr list $interface)
network=$(network $(echo $iplisthost | awk '{print $4}'| cut -d/ -f1) $(echo $iplisthost | awk '{print $4}' | cut -d/ -f2))
networkmask=$(echo $iplisthost | awk '{print $4}' | cut -d/ -f2)


iplistguest=$(qm guest cmd $proxmoxguest network-get-interfaces | jq '.[]."ip-addresses"[] | select(."ip-address-type" == "ipv4") | ."ip-address"')
for i in $(echo $iplistguest|sed 's/"//g'); do
        if grep -q $network <<< $(network $i $networkmask); then
                echo $i
        fi

done
}

prereqtest(){
function testExec {
#$1 >/dev/null 2>&1
which "$1" > /dev/null 2>&1
ret=$?
nr=$#
if [ $ret -ne "0" ]
then
	     echo "missing bin: $1"
	     exit 1
else
     echo "$1: OK"
fi

}

input="prereqlist"
while IFS=' ' read -r line;
do
  testExec "$line"
done < "$input"

}

downloadimage(){
cloudimageurl=$1

rm  $(basename $cloudimageurl).part
if [ ! -e "$(basename $cloudimageurl)" ]
then
	out=$(wget -S --spider --method HEAD $cloudimageurl 2>&1)
	if echo $out | grep -q "Content-Type: application/octet-stream";
	then
		echo "Downloading $(basename $cloudimageurl)"
		wget -S $cloudimageurl -O $(basename $cloudimageurl).part
		mv $(basename $cloudimageurl).part $(basename $cloudimageurl)
	else
		echo "ERROR: Invalid URL"
		exit 1
	fi
fi
}


installpackages(){
imagefile=$1
packagelistfile=$2
virt-customize -a $imagefile --install $(paste -d, -s $packagelistfile)
}

custommotd(){
imagefile=$1
motd=$2
virt-customize -a $imagefile --run-command "printf \"$motd\" > /etc/motd"
}

runcommands(){
imagefile=$1
#test existance and type

input="$2"
while IFS= read -r line
do
virt-customize -a $imagefile --run-command "$line"
done < "$input"
}


setfirstbootscript(){
imagefile=$1
script=$2

virt-customize -a $imagefile --firstboot=$script
}

truncatemachineid(){
imagefile=$1
virt-customize -a $imagefile --truncate /etc/machine-id
}

deployvm(){
storagepool=$1
image=$2
pveid=$3
disksize=$4
hostname=$5
bridge=$6
user=$7
publickey=$8

#lock somehow this id ??

qm create $pveid --memory 2048 --net0 virtio,bridge=$bridge
qm importdisk $pveid $image $storagepool --format qcow2 >/dev/null
disk=$(pvesh get /nodes/localhost/qemu/$pveid/config  --output-format json | jq -r 'last(to_entries[]|select(.key|startswith("unused"))).value')
qm set $pveid --scsihw virtio-scsi-pci --scsi0 $disk
qm set $pveid --agent enabled=1,fstrim_cloned_disks=1
qm set $pveid --name $hostname

qm set $pveid --ide2 $storagepool:cloudinit
qm set $pveid --boot c --bootdisk scsi0
qm set $pveid --serial0 socket --vga serial0
qm set $pveid --ciuser ${user}
qm set $pveid --sshkey ${publickey}

qm disk resize $pveid scsi0 $disksize

rm $image
}

templatevm(){
qm template $1
}
