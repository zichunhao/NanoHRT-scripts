import json
from pathlib import Path
import re
from typing import Optional

class ScaleFactorCorrector:
    def __init__(self, global_config: dict, sf_results: dict):
        """Initialize ScaleFactorCorrector with configuration and results.
        
        Args:
            global_config: Configuration dictionary containing WP definitions and pt ranges
            sf_results: Dictionary containing scale factors and uncertainties
        """
        self.config = global_config
        self.results = sf_results
        
        # Extract WP ranges
        self.wp_ranges = self.config['tagger']['wps']
        
        # Build pt range mapping
        self.pt_ranges = {}
        pt_pattern = re.compile(r'WP\d+_pt(\d+)to(\d+)')
        for key in sf_results.keys():
            match = pt_pattern.match(key)
            if match:
                low, high = int(match.group(1)), int(match.group(2))
                pt_key = f"pt{low}to{high}"
                if pt_key not in self.pt_ranges:
                    self.pt_ranges[pt_key] = (low, high)
    
    def _get_wp_for_score(self, score: float) -> Optional[str]:
        """Get working point name for a given score value."""
        for wp_name, (low, high) in self.wp_ranges.items():
            if low <= score < high:
                return wp_name
        return None

    def _get_pt_range_key(self, pt: float) -> str:
        """Get pt range key for accessing results."""
        for key, (low, high) in self.pt_ranges.items():
            if low <= pt < high or (pt >= low and high > 99999):  # Handle special case for highest bin
                return key
        raise ValueError(f"No pt range found for pt={pt}")

    def _get_variation(self, wp_pt_key: str, variation_name: str) -> dict:
        """Get variation values for a specific WP and pt range."""
        try:
            return self.results[wp_pt_key][variation_name]
        except KeyError:
            raise KeyError(f"No variation found for {variation_name} in {wp_pt_key}")

    def get_variation(self, score: float, pt: float, variation_name: str) -> dict:
        """Get variation values for specific score and pt."""
        wp = self._get_wp_for_score(score)
        if wp is None:
            raise ValueError(f"Score {score} does not fall into any working point range")
            
        pt_key = self._get_pt_range_key(pt)
        wp_pt_key = f"{wp}_{pt_key}"
        
        return self._get_variation(wp_pt_key, variation_name)

    def get_jer(self, score: float, pt: float) -> dict:
        """Get JER variation for specific score and pt."""
        return self.get_variation(score, pt, "jer")
    
    def get_jes(self, score: float, pt: float) -> dict:
        """Get JES variation for specific score and pt."""
        return self.get_variation(score, pt, "jes")

    def get_SF(self, score: float, pt: float) -> dict:
        """Get scale factor for specific score and pt."""
        return self.get_variation(score, pt, "final")

    def get_eff(self, score: float, pt: float, sample: str = "mc", 
                key: str = "final") -> dict:
        """Get efficiency for specific score and pt.
        
        Args:
            score: Tagger score value
            pt: Jet pt value
            sample: Either 'mc' or 'data'
            key: Access key in efficiencies. If 'final', get final_{sample},
                 otherwise access the key in byMode[key][sample]
        """
        wp = self._get_wp_for_score(score)
        if wp is None:
            raise ValueError(f"Score {score} does not fall into any working point range")
            
        pt_key = self._get_pt_range_key(pt)
        wp_pt_key = f"{wp}_{pt_key}"
        
        if key == "final":
            return self.results[wp_pt_key]["efficiencies"][f"final_{sample}"]
        else:
            return self.results[wp_pt_key]["efficiencies"]["byMode"][key][sample]

    def get_wp_boundaries(self) -> dict[str, tuple[float, float]]:
        """Get dictionary of WP score boundaries."""
        return self.wp_ranges

    def get_pt_boundaries(self) -> dict[str, tuple[float, float]]:
        """Get dictionary of pt range boundaries."""
        return self.pt_ranges

    @staticmethod
    def load_json(path: Path) -> dict:
        """Load JSON file from given path.
        
        Args:
            path: Path to JSON file
            
        Returns:
            Parsed JSON content as dictionary
        """
        with open(path) as f:
            return json.load(f)