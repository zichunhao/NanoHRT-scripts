set -xe;

if [ -z $CMSSW_BASE ]; then
    echo "CMSSW_BASE is not set. Exiting.";
    exit 1;
fi

cd /tmp/$(whoami);
# today=$(date +"%Y%m%d");
# flag="${today}_ak8_qcd_2022"
rm -rf *; 
# jobid=406;
# jobid=0;  # data
# jobid=524;  # top
# jobid=2233;  # Vqq
proxy_path="/afs/cern.ch/user/z/zichun/private/x509up";
# copy the necessary files
# tag="jobs_20240605_ak8_qcd_2022EE"
# TODO: Update path to scripts if needed
source /afs/cern.ch/user/z/zichun/public/GloParT-calib/HRT/scripts/TAG.sh;
if [ -z $TAG ]; then
    echo "TAG is not set. Exiting.";
    exit 1;
fi
CMSSW_TAR_PATH="/afs/cern.ch/user/z/zichun/public/GloParT-calib/HRT/CMSSW.tar.gz"
dir_name="jobs_${TAG}_ak8_qcd_2022"

IFS=',' read -ra files <<< "${CMSSW_TAR_PATH},${CMSSW_BASE}/src/PhysicsTools/NanoHRTTools/run/processor.py,${CMSSW_BASE}/src/PhysicsTools/NanoHRTTools/run/${dir_name}/mc/metadata.json,${CMSSW_BASE}/src/PhysicsTools/NanoHRTTools/run/${dir_name}/mc/heavyFlavSFTree_cfg.json,${CMSSW_BASE}/src/PhysicsTools/NanoHRTTools/run/keep_and_drop_input.txt,${CMSSW_BASE}/src/PhysicsTools/NanoHRTTools/run/keep_and_drop_output.txt"
for file in "${files[@]}"; do
    cp "$file" .
done

jobids=(0 1000 2233);

for jobid in "${jobids[@]}"; do
    ${CMSSW_BASE}/src/PhysicsTools/NanoHRTTools/run/run_postproc_condor.sh ${jobid} "${proxy_path}"
done

