#!/bin/bash

vhdl=`ls -d  /c/Xilinx/Vivado/20*/bin 2>/dev/null`
# You replace the previous line of code with a hardcoded
# path like this:
# vhdl="/c/Xilinx/Vivado/2022.2/bin"
# MAKE SURE THERE ARE NO SPACES IN YOUR INSTALL PATH
vhdl_versions=($vhdl)
len=${#vhdl_versions[@]}
if [ $len -gt 1 ] 
then
    echo "Found multiple versions of vivado!"
    vhdl=${vhdl_versions[0]}
    echo "Using version $vhdl"
fi
if [ -z "$vhdl" ] 
then 
    echo "Cannot find Xilinx or Vivado on this computer!"
    echo "if this is a windows machine, then "
    echo "follow instructions to install Vivado as described in class"
    ehco "if this is a linux machine, you will also need to edit this script!"
else
    PATH=$PATH:$vhdl
fi

vivado -mode batch -source ./setup_project.tcl