# NanoHRT-scripts
## Set up environment
```bash
cmsrel CMSSW_13_0_13;
cd CMSSW_13_0_13/src/PhysicsTools;
mkdir -p CMSSW_13_0_13/src/PhysicsTools;
git clone git@github.com:zichunhao/nanoAOD-tools.git NanoAODTools;
git clone git@github.com:zichunhao/NanoHRT-tools.git NanoHRTTools;
scram b -j 8;
```

# Run the script
```bash
# you are already in the scripts directory
# step 0: update TAG.sh if necessary
# step 1: create condor script
./batch_GloParT.sh 1
# step 2: submit condor job
./batch_GloParT.sh 2
# step 3: add weights to MCs
./batch_GloParT.sh 3
# merge outputs
./merge_final.sh
```