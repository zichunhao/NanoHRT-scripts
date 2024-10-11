era="2022"; 
pattern="WtoLNu-2Jets_0J"; 
path="/eos/user/z/zichun/higgs/HH4b-calib/HRT_ParT/GloParTStage2_20241009_ak8_qcd_${era}/mc/pieces"; 

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
mkdir -p ${path}/${pattern}_more; 

step=$1;

if [ $step -eq 1 ]; then
    echo "Moving"
    mv ${path}/${pattern}_*_tree.root ${path}/${pattern}_more; 
elif [ $step -eq 2 ]; then 
    set -xe;
    for i in {0..9}; do 
        python3 ${SCRIPT_DIR}/haddnano.py ${path}/${pattern}_${i}_tree.root ${path}/${pattern}_more/${pattern}_*${i}_tree.root; 
    done
else
    echo "step is either 1 or 2"
    exit
fi