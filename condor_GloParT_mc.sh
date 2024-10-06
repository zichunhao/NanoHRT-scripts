curr_dir=$(pwd);

if [ -z $CMSSW_BASE ]; then
    echo "CMSSW_BASE is not set. Exiting.";
    exit 1;
fi

USAGE="Usage: $0 <year> <step: {1, 2, 3}>";

# parse the arg: 0 or 1
if [ -z $2 ]; then
    echo $USAGE;
    echo "No argument is provided. Exiting.";
    exit 1;
fi

YEAR=$1;
step=$2;

if [ ${step} -ne 1 ] && [ ${step} -ne 2 ] && [ ${step} -ne 3 ]; then
    echo $USAGE;
    echo "Invalid argument (step $2) is provided. Exiting.";
    exit 1;
fi

# CERN lxplus
# EOS_PATH=/eos/user/z/zichun
# Fermilab LPC
EOS_PATH=/eos/uscms/store/user/zhao1  
EOS_PROJ_PATH=${EOS_PATH}/HH4b/GloParT-calib

# source /uscms/home/zhao1/eos/HH4b/GloParT-calib/NanoHRT-scripts/TAG.sh;        # CERN lxplus
source /uscms/home/zhao1/nobackup/HH4b/GloParT-calib/NanoHRT-scripts/TAG.sh;  # Fermilab LPC
echo "TAG: ${TAG}";

set -xe;

# Constants

# CERN lxplus
# INPUT="/eos/cms/store/group/phys_higgs/nonresonant_HH/NanoAOD_v12/sixie/${YEAR}/";
# OUTPUT="/eos/user/z/zichun/higgs/Hbb/HRT/HeavyFlavNtuples/${TAG}" 

# Fermilab LPC
# INPUT="/eos/uscms/store/user/lpcdihiggsboost/NanoAOD_v12_ParT"
INPUT="/eos/uscms/"
OUTPUT="${EOS_PROJ_PATH}/NanoHRT_outputs/${TAG}"
N_FILES_PER_JOB=20;
CHANNEL="qcd";
JET_TYPE="ak8";
filelist_path="${CMSSW_BASE}/src/PhysicsTools/NanoHRTTools/run/custom_samples/nanoindex_v12v2_private.json"

DIR_RUN=${CMSSW_BASE}/src/PhysicsTools/NanoHRTTools/run;
cd ${DIR_RUN};

# Run scripts
if [ ${step} -eq 1 ]; then
    # Step 1: Generate the condor submission files
    # remove -i ${INPUT} if remote
    # add --prefetch to download the files locally to tmp
    python3 runHeavyFlavTrees.py \
    -i ${INPUT} \
    -o ${OUTPUT} \
    --nfiles-per-job ${N_FILES_PER_JOB} \
    --sample-dir custom_samples \
    --jet-type ${JET_TYPE} \
    --channel ${CHANNEL} \
    --year ${YEAR} \
    --sfbdt 0 \
    --datasets ${filelist_path};
elif [ ${step} -eq 2 ]; then
    # Step 2: Submit the jobs to condor
    cd "${DIR_RUN}/jobs_${TAG}_${JET_TYPE}_${CHANNEL}_${YEAR}/mc";
    condor_submit "submit.cmd";
else
    # Step 3: add cross-section (xsec) weights and pileup (pu) weights
    # and hadd the output files
    # remove -i ${INPUT} if remote
    # add --prefetch to download the files locally to tmp
    python3 runHeavyFlavTrees.py \
    --add-weight --weight-file "${DIR_RUN}/samples/xsecs_run3.py" \
    -i ${INPUT} \
    -o ${OUTPUT} \
    --nfiles-per-job ${N_FILES_PER_JOB} \
    --sample-dir custom_samples \
    --jet-type ${JET_TYPE} \
    --channel ${CHANNEL} \
    --year ${YEAR} \
    --sfbdt 0 \
    --datasets ${filelist_path};
fi

cd $curr_dir;