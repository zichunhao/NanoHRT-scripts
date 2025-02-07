import json
from pathlib import Path
import numpy as np
from typing import Dict, Any, Optional, Tuple
from numpy.typing import ArrayLike
from coffea.lookup_tools.dense_lookup import dense_lookup


def create_combined_sf(
    global_config: dict, sf_results: dict
) -> Dict[str, dense_lookup]:
    """Create combined scale factors with statistical variations.

    Args:
        global_config: Configuration dictionary containing WP definitions
        sf_results: Dictionary containing scale factors and uncertainties

    Returns:
        Dictionary containing dense_lookup objects for nominal and variations
    """
    # Extract WP bins from global config
    wp_ranges = global_config["tagger"]["wps"]
    wp_bins = np.array([wp_ranges[wp][0] for wp in sorted(wp_ranges)] + [1.0])

    # Extract PT bins from results
    pt_edges = set()
    for key in sf_results:
        wp, pt_range = key.split("_")
        start, end = map(int, pt_range.replace("pt", "").split("to"))
        pt_edges.add(start)
        pt_edges.add(end)
    pt_bins = np.array(sorted(pt_edges))

    # Create edges for lookup
    edges = (wp_bins, pt_bins)

    # Initialize value arrays
    values = {
        "nominal": [],  # central values
        "stat_up": [],  # central + high
        "stat_dn": [],  # central - low
    }

    # Fill values
    for i, wp in enumerate(sorted(wp_ranges.keys())):
        nominal_row = []
        high_row = []
        low_row = []

        for j in range(len(pt_bins) - 1):
            start, end = pt_bins[j], pt_bins[j + 1]
            key = f"{wp}_pt{start}to{end}"
            result = sf_results[key]["final"]

            nominal_row.append(result["central"])
            high_row.append(result["central"] + result["high"])
            low_row.append(result["central"] - result["low"])

        values["nominal"].append(nominal_row)
        values["stat_up"].append(high_row)
        values["stat_dn"].append(low_row)

    # Convert to numpy arrays
    values = {k: np.array(v) for k, v in values.items()}

    # Create dense lookups
    combined_sf = {
        "nominal": dense_lookup(values["nominal"], edges),
        "stat_up": dense_lookup(values["stat_up"], edges),
        "stat_dn": dense_lookup(values["stat_dn"], edges),
    }

    return combined_sf


class ScaleFactorLookup:
    def __init__(self, global_config: dict, sf_results: dict):
        """Initialize scale factor lookup with configuration and results.

        Args:
            global_config: Configuration dictionary containing WP definitions
            sf_results: Dictionary containing scale factors and uncertainties
        """
        self.lookups = create_combined_sf(global_config, sf_results)
        self.config = global_config

        # Store boundaries
        self.wp_ranges = self.config["tagger"]["wps"]
        self.pt_edges = set()
        for key in sf_results:
            _, pt_range = key.split("_")
            start, end = map(int, pt_range.replace("pt", "").split("to"))
            self.pt_edges.add(start)
            self.pt_edges.add(end)
        self.pt_bins = np.array(sorted(self.pt_edges))

    def get_sf(
        self, txbb: ArrayLike, pt: ArrayLike, variation: str = "nominal"
    ) -> ArrayLike:
        """Get scale factors for given txbb and pt.

        Args:
            txbb: Array of tagger score values
            pt: Array of jet pt values
            variation: Which variation to use ('nominal', 'stat_up', or 'stat_dn')

        Returns:
            Array of scale factors
        """
        txbb = np.asarray(txbb)
        pt = np.asarray(pt)
        return self.lookups[variation](txbb, pt)

    def restrict_sf(
        self,
        txbb: ArrayLike,
        pt: ArrayLike,
        variation: str = "nominal",
        score_input_range: Optional[Tuple[float, float]] = None,
        pt_input_range: Optional[Tuple[float, float]] = None,
    ) -> ArrayLike:
        """Get restricted scale factors.

        Args:
            txbb: Array of tagger score values
            pt: Array of jet pt values
            variation: Which variation to use ('nominal', 'stat_up', or 'stat_dn')
            score_input_range: Optional tuple of (min, max) score values
            pt_input_range: Optional tuple of (min, max) pt values

        Returns:
            Array of scale factors with restrictions applied
        """
        txbb = np.asarray(txbb)
        pt = np.asarray(pt)

        sf = self.get_sf(txbb, pt, variation)

        if score_input_range is not None:
            sf[txbb < score_input_range[0]] = 1.0
            sf[txbb > score_input_range[1]] = 1.0

        if pt_input_range is not None:
            sf[pt < pt_input_range[0]] = 1.0
            sf[pt > pt_input_range[1]] = 1.0

        return sf

    @staticmethod
    def load_json(path: Path) -> dict:
        """Load JSON file from given path."""
        with open(path) as f:
            return json.load(f)
