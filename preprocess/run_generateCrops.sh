#!/bin/sh
# script for execution of deployed applications
#
# Sets up the MATLAB Runtime environment for the current $ARCH and executes 
# the specified command.
#
if [[ "${SLURM_JOBID:-none}" == "none" ]];then
  echo "not running in job allocation"
  exit 64
fi
if [[ ! -d /lscratch/${SLURM_JOBID} ]]; then
  echo "lscratch directory does not exist; submit with --gres=lscratch"
  exit 65
fi
MCRdir=/lscratch/${SLURM_JOBID}/mcr${RANDOM}_${RANDOM}
mkdir -p $MCRdir
export MCR_CACHE_ROOT=$MCRdir

exe_name=$0
exe_dir=`dirname "$0"`
echo "------------------------------------------"
if [ "x$1" = "x" ]; then
  echo Usage:
  echo    $0 \<deployedMCRroot\> args
else
  echo Setting up environment variables
  MCRROOT="$1"
  echo ---
  LD_LIBRARY_PATH=.:${MCRROOT}/runtime/glnxa64 ;
  LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}/bin/glnxa64 ;
  LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}/sys/os/glnxa64;
  LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}/sys/opengl/lib/glnxa64;
  export LD_LIBRARY_PATH;
  echo LD_LIBRARY_PATH is ${LD_LIBRARY_PATH};
  shift 1
  args=
  while [ $# -gt 0 ]; do
      token=$1
      args="${args} \"${token}\"" 
      shift
  done
  eval "\"${exe_dir}/generateCrops\"" $args
fi
exit

