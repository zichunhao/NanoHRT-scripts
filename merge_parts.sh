era="2022"; 
pattern="WtoLNu-2Jets_0J"; 
path="/eos/user/z/zichun/higgs/HH4b-calib/HRT_ParT/GloParTStage2_20241009_ak8_qcd_${era}/mc/pieces"; 
output_path="/eos/user/z/zichun/higgs/HH4b-calib/HRT_ParT/GloParTStage2_20241009_ak8_qcd_${era}/mc/outputs";
mkdir -p ${output_path};

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
mkdir -p ${path}/${pattern}_more; 

TMP_DIR=/tmp/$(whoami)/nanoHRT/${pattern};
mkdir -p ${TMP_DIR};
cd ${TMP_DIR};
echo "Moving"
mv ${path}/${pattern}_*_tree.root ${path}/${pattern}_more; 

set -xe;
for i in {0..9}; do 
    # use a tmp dir to avoid overwriting the original files in case re-run
    tgt=${TMP_DIR}/${pattern}_${i}_tree.root;
    python3 ${SCRIPT_DIR}/haddnano.py ${tgt} ${path}/${pattern}_more/${pattern}_${i}_tree.root; 
done

mv ${TMP_DIR}/*.root ${output_path};
