#!/bin/bash

curr_dir=$(pwd);
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )";

echo "script's dir: $SCRIPT_DIR";

if [ -z $CMSSW_BASE ]; then
    echo "CMSSW_BASE is not set. Exiting.";
    exit 1;
fi

USAGE="Usage: $0 <year> <step: {1, 2, 3}> [mode:data/mc/both, default: both]";

if [ -z $2 ]; then
    echo $USAGE;
    echo "No argument is provided. Exiting.";
    exit 1;
fi

YEAR=$1;
step=$2;
mode=${3:-both};

case $mode in
    data|mc|both) ;;
    *)
        echo "Invalid mode: $mode. Using default: both";
        mode="both"
        ;;
esac

if [ ${step} -ne 1 ] && [ ${step} -ne 2 ] && [ ${step} -ne 3 ]; then
    echo $USAGE;
    echo "Invalid argument (step $2) is provided. Exiting.";
    exit 1;
fi

# get tags
source ${SCRIPT_DIR}/TAG.sh;

set -xe;

# Uncomment for CERN lxplus
EOS_PATH=/eos/user/z/zichun;
INPUT_TAG="--prefetch"  # remote from LPC
OUTPUT="${EOS_PATH}/higgs/HH4b-calib/HRT_ParT/${TAG}"

# Uncomment for Fermilab LPC
# EOS_PATH=/eos/uscms/store/user/zhao1  
# EOS_PROJ_PATH=${EOS_PATH}/HH4b/GloParT-calib
# INPUT="/eos/uscms/"
# INPUT_TAG="-i ${INPUT}"  # local from LPC
# OUTPUT="${EOS_PROJ_PATH}/NanoHRT_outputs/${TAG}"

echo "TAG: ${TAG}";

# Constants
CHANNEL="qcd";
JET_TYPE="ak8";
filelist_path="${CMSSW_BASE}/src/PhysicsTools/NanoHRTTools/run/custom_samples/nanoindex_v12v2_private.json"
DIR_RUN=${CMSSW_BASE}/src/PhysicsTools/NanoHRTTools/run;
cd ${DIR_RUN};

process_mode() {
    local mode=$1
    local N_FILES_PER_JOB=1
    local RUN_DATA=""
    
    if [ "$mode" == "mc" ]; then
        N_FILES_PER_JOB=2
        RUN_DATA=""
    else
        N_FILES_PER_JOB=1
        RUN_DATA="--run-data"
    fi
    
    case $step in
        1)
            # Generate the condor submission files
            python3 runHeavyFlavTrees.py \
            ${RUN_DATA} \
            ${INPUT_TAG} \
            -o ${OUTPUT} \
            --nfiles-per-job ${N_FILES_PER_JOB} \
            --sample-dir custom_samples \
            --jet-type ${JET_TYPE} \
            --channel ${CHANNEL} \
            --year ${YEAR} \
            --sfbdt 0 \
            --datasets ${filelist_path}
            ;;
        2)
            # Submit the jobs to condor
            cd "${DIR_RUN}/jobs_${TAG}_${JET_TYPE}_${CHANNEL}_${YEAR}/${mode}";
            condor_submit "submit.cmd"
            ;;
        3)
            # Add cross-section (xsec) weights and pileup (pu) weights and hadd the output files
            python3 runHeavyFlavTrees.py \
            ${RUN_DATA} \
            --add-weight --weight-file "${DIR_RUN}/samples/xsec_run3_ParT.json" \
            ${INPUT_TAG} \
            -o ${OUTPUT} \
            --nfiles-per-job ${N_FILES_PER_JOB} \
            --sample-dir custom_samples \
            --jet-type ${JET_TYPE} \
            --channel ${CHANNEL} \
            --year ${YEAR} \
            --sfbdt 0 \
            --datasets ${filelist_path}
            ;;
    esac
}

if [ "$mode" == "both" ]; then
    process_mode "data"
    process_mode "mc"
else
    process_mode "$mode"
fi

cd $curr_dir;