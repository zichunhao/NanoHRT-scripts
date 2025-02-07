import argparse
from pathlib import Path
import uproot
import numpy as np
from sf_lookup import ScaleFactorLookup
from tqdm import tqdm


def parse_args():
    parser = argparse.ArgumentParser(description="Apply scale factors to events")
    parser.add_argument(
        "--input-dir",
        type=str,
        required=True,
        help="Input directory containing ROOT files",
    )
    parser.add_argument(
        "--signal-types",
        nargs="+",
        required=True,
        help="List of signal types to process",
    )
    parser.add_argument(
        "--output-dir",
        type=str,
        required=True,
        help="Output directory for processed files",
    )
    parser.add_argument(
        "--json-dir",
        type=Path,
        default=None,
        help="Directory containing JSON files. If None, uses jsons/{era}",
    )
    parser.add_argument(
        "--pt-key",
        type=str,
        default="fj_1_pt",
        help="Key for pT in ROOT file",
    )
    parser.add_argument(
        "--txbb-key",
        type=str,
        default="fj_1_globalParT_XbbVsQCD",
        help="Key for TXbb in ROOT file",
    )
    parser.add_argument(
        "--is-data",
        action="store_true",
        help="If true, all scale factors are set to 1",
    )
    parser.add_argument(
        "--chunk-size",
        type=int,
        default=-1,
        help="Number of events to process at once. Default -1 means process all events at once.",
    )

    return parser.parse_args()


def setup_sf_lookup(json_dir: str) -> ScaleFactorLookup:
    json_dir = Path(json_dir or f"jsons")
    global_config = ScaleFactorLookup.load_json(json_dir / "global_cfg.json")
    sf_results = ScaleFactorLookup.load_json(json_dir / "sf_eff_values.json")
    return ScaleFactorLookup(global_config, sf_results)


def process_file(
    input_path: Path,
    output_path: Path,
    sf_lookup: ScaleFactorLookup,
    chunk_size: int = -1,
    pt_key: str = "fj_1_pt",
    txbb_key: str = "fj_1_globalParT_XbbVsQCD",
    is_data: bool = False,
) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)

    # Calculate all scale factors
    print("Calculating scale factors...")
    with uproot.open(input_path) as input_file:
        events = input_file["Events"]
        n_events = events.num_entries
        branch_names = events.keys()

        if is_data:
            print("Data mode: setting all scale factors to 1")
            run = events["run"].array(library="np")
            SF = np.ones_like(run)
            SF_up = np.ones_like(run)
            SF_down = np.ones_like(run)
        else:
            pt = events[pt_key].array(library="np")
            TXbb = events[txbb_key].array(library="np")
            SF = sf_lookup.restrict_sf(txbb=TXbb, pt=pt)
            stat_up = sf_lookup.restrict_sf(txbb=TXbb, pt=pt, variation="stat_up")
            stat_down = sf_lookup.restrict_sf(txbb=TXbb, pt=pt, variation="stat_dn")
            SF_up = SF + stat_up
            SF_down = SF - stat_down

    # Write in chunks
    print("Writing output...")

    # If chunk_size is -1, write all events at once
    if chunk_size == -1:
        chunk_size = n_events

    with uproot.recreate(output_path) as output_file:
        pbar = tqdm(
            total=n_events,
            desc="Processing events",
            unit="events",
            unit_scale=True,
            bar_format="{desc}: {percentage:3.0f}%|{bar}| {n_fmt}/{total_fmt} events [{elapsed}<{remaining}]",
        )

        for start in range(0, n_events, chunk_size):
            stop = min(start + chunk_size, n_events)

            # Reopen file for each chunk
            with uproot.open(input_path) as input_file:
                events = input_file["Events"]

                # Read original branches for this chunk
                chunk_dict = {}
                for key in branch_names:
                    chunk_dict[key] = events[key].array(
                        library="np", entry_start=start, entry_stop=stop
                    )

                # Add corresponding scale factor chunks
                chunk_dict["SF_TXbb"] = SF[start:stop]
                chunk_dict["SF_TXbb_up"] = SF_up[start:stop]
                chunk_dict["SF_TXbb_down"] = SF_down[start:stop]

                # Write chunk to output file
                if start == 0:
                    # New file
                    output_file["Events"] = chunk_dict
                else:
                    output_file["Events"].extend(chunk_dict)

                # Update progress bar
                pbar.update(stop - start)

        pbar.close()


def main():
    args = parse_args()
    print(f"Arguments: {args}")

    sf_lookup = setup_sf_lookup(args.json_dir)

    input_dir = Path(args.input_dir)
    output_dir = Path(args.output_dir)
    print(f"Processing in {input_dir} and saving to {output_dir}")

    for signal_type in args.signal_types:
        input_path = input_dir / f"{signal_type}.root"
        output_path = output_dir / f"{signal_type}.root"

        print(f"Processing {signal_type}...")
        process_file(
            input_path,
            output_path,
            sf_lookup,
            chunk_size=args.chunk_size,
            pt_key=args.pt_key,
            txbb_key=args.txbb_key,
            is_data=args.is_data,
        )
        print(f"Saved output to {output_path}")


if __name__ == "__main__":
    main()
