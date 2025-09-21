"""Peer comparison service."""

import pandas as pd
from typing import Dict, Any, List
from pathlib import Path

from ..core.config import get_settings
from ..core.logging import get_logger

logger = get_logger(__name__)


class PeerComparisonService:
    """Service for peer cohort analysis."""
    
    def __init__(self):
        """Initialize peer comparison service."""
        self.settings = get_settings()
        
    async def get_peer_metrics(self, startup_metrics: Dict[str, Any]) -> Dict[str, Any]:
        """Get peer comparison metrics.
        
        Args:
            startup_metrics: Current startup metrics
            
        Returns:
            Peer comparison data
        """
        if self.settings.USE_BIGQUERY:
            return await self._get_bigquery_peers(startup_metrics)
        else:
            return self._get_csv_peers(startup_metrics)
    
    def _get_csv_peers(self, startup_metrics: Dict[str, Any]) -> Dict[str, Any]:
        """Get peer data from CSV.
        
        Args:
            startup_metrics: Current startup metrics
            
        Returns:
            Peer comparison data
        """
        csv_path = Path("data/demo/peers.csv")
        
        if not csv_path.exists():
            # Create mock data
            mock_data = pd.DataFrame([
                {"company": "Peer1", "arr": 5000000, "growth": 2.5, "margin": 0.7},
                {"company": "Peer2", "arr": 8000000, "growth": 2.0, "margin": 0.75},
                {"company": "Peer3", "arr": 3000000, "growth": 3.0, "margin": 0.65},
            ])
            csv_path.parent.mkdir(parents=True, exist_ok=True)
            mock_data.to_csv(csv_path, index=False)
        
        df = pd.read_csv(csv_path)
        
        return {
            "percentile_arr": 0.6,
            "percentile_growth": 0.7,
            "percentile_margin": 0.5,
            "peer_count": len(df),
            "top_quartile_arr": 7500000,
            "median_growth": 2.5
        }
    
    async def _get_bigquery_peers(self, startup_metrics: Dict[str, Any]) -> Dict[str, Any]:
        """Get peer data from BigQuery.
        
        Args:
            startup_metrics: Current startup metrics
            
        Returns:
            Peer comparison data
        """
        # Placeholder for BigQuery implementation
        return self._get_csv_peers(startup_metrics)
