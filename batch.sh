if [ -z $1 ]; then
    echo "Usage: source batch.sh step [mode:data/mc/both]"
    return
fi
step=$1
modes="mc"
if [ $2 == "data" ]; then
    modes="data"
elif [ $2 == "mc" ]; then
    modes="mc"
elif [ $2 == "both" ]; then
    modes="data mc"
else
    echo "Invalid mode: $2"
    return
fi

for mode in $modes; do
    echo "mode: $mode"
    
    script="/uscms/home/zhao1/nobackup/HH4b/GloParT-calib/NanoHRT-scripts/condor_GloParT_${mode}.sh"
    eras=("2022" "2022EE" "2023" "2023BPix")

    for era in ${eras[@]}; do
        echo "$script $era $step"
        bash $script $era $step
    done
done