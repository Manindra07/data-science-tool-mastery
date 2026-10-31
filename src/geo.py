"""Geographic helpers used in Case File 01."""
import numpy as np


def haversine_km(lat, lon, lat0, lon0):
    """Great-circle distance in km from points (lat, lon) to one point (lat0, lon0).

    Works on NumPy arrays or Pandas Series, with no Python loop needed.
    """
    lat, lon, lat0, lon0 = map(np.radians, (lat, lon, lat0, lon0))
    a = (np.sin((lat - lat0) / 2) ** 2
         + np.cos(lat0) * np.cos(lat) * np.sin((lon - lon0) / 2) ** 2)
    return 2 * 6371.0088 * np.arcsin(np.sqrt(a))  # Earth's mean radius in km
