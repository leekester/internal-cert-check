#!/bin/bash

vnetAdrRange=$1
subnetSize=$2

echo $1
echo $2

MaxValue=255
p=1
IFS='/'
read -ra strarr <<< "$vnetAdrRange"
ip=$strarr
vnetRange=${strarr[1]}
##count=$(subnetCount)
IFS=','
read -ra arr <<< "$subnetSize"
count=${#arr[@]}
baseaddr="$(echo $ip | cut -d. -f1-2)"
lsv="$(echo $ip | cut -d. -f3)"
#n=$(subnetCount)
n=${#arr[@]}
combined=""
for i in $(seq 0 $(($n > 0? $n-1: 0))); do
while [ $count -gt 0 ] 
do
for val in "${arr[@]}";
do
#if [ $(subnetSizeEqual) = false ]
#then

if [ $p = 1 ]
then
if [ $val = /23 ]
then
token="$baseaddr.$lsv.0$val"

elif [  $val = /24 ]
then
token="$baseaddr.$lsv.0$val"
#lsv=$(( $lsv + 1 ))

elif [ $val = /25 ]
then
token="$baseaddr.$lsv.0$val"

elif [ $val = /26 ]
then
token="$baseaddr.$lsv.0$val"
#lsv=$(( $lsv + 1 ))

elif [ $val = /27 ]
then
token="$baseaddr.$lsv.0$val"
#lsv=$(( $lsv + 1 ))

elif [ $val = /28 ] 
then
#lsv1=$(( $lsv + 16 ))
token="$baseaddr.$lsv.0$val"
#lsv=$(( $lsv + 1 ))
fi
#############################################################
else 
q=$(( $p - 2 ))
##echo $p
##echo $q

if [ $p == 6 -a $val = /23 ]
then
lsv=$(( $lsv + 2 ))
token="$baseaddr.$lsv.0$val"

elif [ $val = /24 -a ${arr[$q]} = /23 ]
then
lsv=$(( $lsv + 2 ))
token="$baseaddr.$lsv.0$val"

elif [ $val = /24 -a ${arr[q]} = /24 ]
then
lsv=$(( $lsv + 1 ))
token="$baseaddr.$lsv.0$val"

elif [ $val = /25 -a ${arr[q]} = /23 ]
then
lsv=$(( $lsv + 2 ))
token="$baseaddr.$lsv.0$val"

elif [ $val = /25 -a ${arr[q]} = /24 ]
then
lsv=$(( $lsv + 1 ))
token="$baseaddr.$lsv.0$val"

elif [ $val = /25 -a ${arr[q]} = /25 ]
then
if [ $lsv1 -gt 127 ]
then
lsv=$(( $lsv + 1 ))
lsv1=0
else
lsv1=$(( $lsv1 + 128 ))
fi
token="$baseaddr.$lsv.$lsv1$val"

elif [ $val = /26 -a ${arr[$q]} = /23 ]
then
lsv=$(( $lsv + 2 ))
#lsv1=$(( $lsv1 + 64 ))
echo "test23-26"
token="$baseaddr.$lsv.0$val"

elif [ $val = /26 -a ${arr[$q]} = /24 ]
then
lsv=$(( $lsv + 1 ))
#lsv1=$(( $lsv1 + 64 ))
token="$baseaddr.$lsv.0$val"

elif [ $val = /26 -a ${arr[$q]} = /25 ]
then
if [ $lsv1 -gt 127 ]
then
lsv=$(( $lsv + 1 ))
lsv1=0
else
lsv1=$(( $lsv1 + 128 ))
fi
token="$baseaddr.$lsv.$lsv1$val"

elif [ $val = /26 -a ${arr[$q]} = /26 ]
then
if [ $lsv1 -gt 191 ]
then
lsv=$(( $lsv + 1 ))
lsv1=0
else
lsv1=$(( $lsv1 + 64 ))
fi
echo ${arr[$q]}
token="$baseaddr.$lsv.$lsv1$val"

elif [ $val = /27 -a ${arr[$q]} = /23 ]
then
lsv=$(( $lsv + 2 ))
#lsv1=$(( $lsv1 + 64 ))
token="$baseaddr.$lsv.0$val"

elif [ $val = /27 -a ${arr[$q]} = /24 ]
then
lsv=$(( $lsv + 1 ))
#lsv1=$(( $lsv1 + 64 ))
token="$baseaddr.$lsv.0$val"

elif [ $val = /27 -a ${arr[$q]} = /25 ]
then
if [ $lsv1 -gt 127 ]
then
lsv=$(( $lsv + 1 ))
lsv1=0
else
lsv1=$(( $lsv1 + 128 ))
fi
token="$baseaddr.$lsv.$lsv1$val"

elif [ $val = /27 -a ${arr[$q]} = /26 ]
then
if [ $lsv1 -gt 191 ]
then
lsv=$(( $lsv + 1 ))
lsv1=0
else
lsv1=$(( $lsv1 + 64 ))
fi
token="$baseaddr.$lsv.$lsv1$val"

elif [ $val = /27 -a ${arr[$q]} = /27  ]
then
if [ $lsv1 -gt 223 ]
then
lsv=$(( $lsv + 1 ))
lsv1=0
else
lsv1=$(( $lsv1 + 32 ))
fi
token="$baseaddr.$lsv.$lsv1$val"

elif [ $val = /28 -a ${arr[$q]} = /23 ]
then
lsv=$(( $lsv + 2 ))
#lsv1=$(( $lsv1 + 64 ))
token="$baseaddr.$lsv.0$val"

elif [ $val = /28 -a ${arr[$q]} = /24 ]
then
lsv=$(( $lsv + 1 ))
#lsv1=$(( $lsv1 + 64 ))
token="$baseaddr.$lsv.0$val"

elif [ $val = /28 -a ${arr[$q]} = /25 ]
then
if [ $lsv1 -gt 127 ]
then
lsv=$(( $lsv + 1 ))
lsv1=0
else
lsv1=$(( $lsv1 + 128 ))
fi
token="$baseaddr.$lsv.$lsv1$val"

elif [ $val = /28 -a ${arr[$q]} = /26 ]
then
if [ $lsv1 -gt 191 ]
then
lsv=$(( $lsv + 1 ))
lsv1=0
else
lsv1=$(( $lsv1 + 64 ))
fi
token="$baseaddr.$lsv.$lsv1$val"

elif [ $val = /28 -a ${arr[$q]} = /27  ]
then
if [ $lsv1 -gt 223 ]
then
lsv=$(( $lsv + 1 ))
lsv1=0
else
lsv1=$(( $lsv1 + 32 ))
fi
token="$baseaddr.$lsv.$lsv1$val"

elif [ $val = /28 -a ${arr[$q]} = /28  ]
then
if [ $lsv1 -gt 238 ]
then
lsv=$(( $lsv + 1 ))
lsv1=0
else
lsv1=$(( $lsv1 + 16 ))
fi
token="$baseaddr.$lsv.$lsv1$val"
fi
fi
count=$(( $count - 1))
p=$(( $p + 1 ))
combined="${combined}${combined:+,}$token"
done
done
done
echo $combined
echo "##vso[task.setvariable variable=combined]$combined"
