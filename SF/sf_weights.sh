SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR
HRT_DIR="/afs/cern.ch/user/z/zichun/eos/higgs/HH4b-calib/HRT_ParT"
DATA_TYPES="jetht"
MC_TYPES="ggfhh4b qcd top v-qq"

source "../TAG.sh"

process_era() {
    local era=$1
    json_dir="${SCRIPT_DIR}/jsons/${era}"

    # data
    input_dir="${HRT_DIR}/${TAG}_ak8_qcd_${era}/data/outputs"
    output_dir="${HRT_DIR}/${TAG}_ak8_qcd_${era}/data/outputs_sf_weights"
    python3 sf_weights.py \
    --input-dir $input_dir \
    --signal-types $DATA_TYPES \
    --is-data \
    --json-dir $json_dir \
    --output-dir $output_dir
    
    # mc
    input_dir="${HRT_DIR}/${TAG}_ak8_qcd_${era}/mc/outputs"
    output_dir="${HRT_DIR}/${TAG}_ak8_qcd_${era}/mc/outputs_sf_weights"
    python3 sf_weights.py \
    --input-dir $input_dir \
    --signal-types $MC_TYPES \
    --json-dir $json_dir \
    --output-dir $output_dir
}

# for era in 2022 2022EE 2023 2023BPix; do
# for era in 2022 2023BPix; do
for era in 2022; do
    process_era $era
done
