SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd $SCRIPT_DIR
HRT_DIR="/afs/cern.ch/user/z/zichun/eos/higgs/HH4b-calib/HRT_ParT"
DATA_TYPES="jetht"
# MC_TYPES="ggfhh4b qcd top v-qq"
MC_TYPES="qcd top v-qq ggfhh4b"
CHUNK_SIZE=200000

source "../TAG.sh"

process_era() {
    local era=$1
    local mode="$2"
    local chunk_size=$3
    json_dir="${SCRIPT_DIR}/jsons/${era}"

    echo "Processing era: $era, mode: $mode"

    if [ $mode == "data" ]; then
        input_dir="${HRT_DIR}/${TAG}_ak8_qcd_${era}/data/outputs"
        output_dir="${HRT_DIR}/${TAG}_ak8_qcd_${era}/data/outputs_sf_weights"
        python3 sf_weights.py \
        --is-data \
        --chunk-size $chunk_size \
        --input-dir $input_dir \
        --signal-types $DATA_TYPES \
        --json-dir $json_dir \
        --output-dir $output_dir
    else
        # mc
        input_dir="${HRT_DIR}/${TAG}_ak8_qcd_${era}/mc/outputs"
        output_dir="${HRT_DIR}/${TAG}_ak8_qcd_${era}/mc/outputs_sf_weights"
        python3 sf_weights.py \
        --chunk-size $chunk_size \
        --input-dir $input_dir \
        --signal-types $MC_TYPES \
        --json-dir $json_dir \
        --output-dir $output_dir
    fi
}

for era in 2022 2022EE 2023 2023BPix; do
    for mode in "data" "mc"; do
        process_era $era $mode $CHUNK_SIZE
    done
done

wait
echo "All done"
