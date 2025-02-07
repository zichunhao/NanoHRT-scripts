#!/bin/bash

parent_dir="/eos/home-z/zichun/higgs/HH4b-calib/HRT_ParT"

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source ${SCRIPT_DIR}/TAG.sh;

get_sub_dir() {
    local era=$1
    echo ${TAG}_ak8_qcd_${era}
}

EXEC_MC="python3 ${SCRIPT_DIR}/haddnano.py"
EXEC_DATA="python3 ${SCRIPT_DIR}/haddnano.py"
# EXEC_DATA="hadd -f"

process_files() {
    local type=$1
    local input_dir=$2
    local output_dir=$3

    mkdir -p ${output_dir}

    if [ "$type" == "mc" ]; then
        # QCD
        ${EXEC_MC} ${output_dir}/qcd.root ${input_dir}/QCD_HT-*.root

        # Top
        ${EXEC_MC} ${output_dir}/top.root ${input_dir}/TBbarQ_*.root ${input_dir}/Tbar*.root ${input_dir}/TT*.root ${input_dir}/TWminus*.root

        # ggfhh4b
        ${EXEC_MC} ${output_dir}/ggfhh4b.root ${input_dir}/GluGlutoHHto4B*.root

        # v-qq
        ${EXEC_MC} ${output_dir}/v-qq.root ${input_dir}/Wto2Q*.root ${input_dir}/Zto2Q*.root

    elif [ "$type" == "data" ]; then
        # JetHT
        ${EXEC_DATA} ${output_dir}/jetht.root ${input_dir}/JetMET_*.root
    fi
}

for era in 2022 2022EE 2023BPix 2023; do
    for type in data mc; do
        echo "Processing ${era} ${type}..."
        sub_dir=$(get_sub_dir $era)
        input_dir=${parent_dir}/${sub_dir}/${type}/parts
        output_dir=${parent_dir}/${sub_dir}/${type}/outputs

        process_files $type $input_dir $output_dir &
    done
done

wait
echo "All done!"