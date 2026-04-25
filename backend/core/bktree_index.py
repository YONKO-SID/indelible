import pybktree
import imagehash
from PIL import Image
import json
import os
import logging
from typing import List, Tuple

logger = logging.getLogger("IndelibleBKTree")

class AssetHash:
    """A wrapper class for ImageHash that also holds the creator fingerprint."""
    def __init__(self, hsh: imagehash.ImageHash, fingerprint: str):
        self.hsh = hsh
        self.fingerprint = fingerprint

    def __hash__(self):
        # We need this to be hashable for pybktree
        return hash((str(self.hsh), self.fingerprint))

    def __eq__(self, other):
        return self.hsh == other.hsh and self.fingerprint == other.fingerprint

def distance_func(a: AssetHash, b: AssetHash) -> int:
    """Calculates the Hamming distance between two image hashes."""
    return a.hsh - b.hsh

class BKTreeIndex:
    def __init__(self, registry_file: str = "phash_registry.json"):
        self.registry_file = registry_file
        self.tree = pybktree.BKTree(distance_func)
        self._load_registry()

    def _load_registry(self):
        if os.path.exists(self.registry_file):
            try:
                with open(self.registry_file, "r") as f:
                    data = json.load(f)
                    for item in data:
                        hsh = imagehash.hex_to_hash(item["hash"])
                        asset = AssetHash(hsh, item["fingerprint"])
                        self.tree.add(asset)
                logger.info(f"Loaded {len(data)} assets into BK-Tree index.")
            except Exception as e:
                logger.error(f"Error loading BK-Tree registry: {e}")
        else:
            logger.info("No pHash registry found. Initialized empty BK-Tree.")

    def _save_registry(self):
        # Dump the tree to JSON (we have to iterate the tree items)
        data = []
        for asset in self.tree:
            data.append({
                "hash": str(asset.hsh),
                "fingerprint": asset.fingerprint
            })
        with open(self.registry_file, "w") as f:
            json.dump(data, f, indent=4)

    def add_asset(self, image_path: str, fingerprint: str):
        """Computes the pHash of an image and adds it to the index."""
        try:
            img = Image.open(image_path)
            hsh = imagehash.phash(img)
            asset = AssetHash(hsh, fingerprint)
            self.tree.add(asset)
            self._save_registry()
            logger.info(f"Added asset to index: {fingerprint} with pHash {str(hsh)}")
        except Exception as e:
            logger.error(f"Error adding asset to BK-Tree: {e}")

    def find_matches(self, image_path: str, tolerance: int = 5) -> List[Tuple[int, str]]:
        """
        Finds all assets in the index that match the given image within a certain Hamming distance tolerance.
        Returns a list of tuples: (distance, fingerprint) sorted by distance.
        """
        try:
            img = Image.open(image_path)
            query_hash = imagehash.phash(img)
            query_asset = AssetHash(query_hash, "") # dummy fingerprint for query
            
            # pybktree returns a list of (distance, item)
            results = self.tree.find(query_asset, tolerance)
            
            matches = [(dist, asset.fingerprint) for dist, asset in results]
            matches.sort(key=lambda x: x[0])
            
            return matches
        except Exception as e:
            logger.error(f"Error querying BK-Tree: {e}")
            return []

# Singleton instance
index = BKTreeIndex()
