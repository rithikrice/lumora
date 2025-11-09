"""Google Docs export service."""

import os
from typing import Dict, Any, List, Optional

from ..models.dto import AnalyzeResponse, Evidence
from ..core.config import get_settings
from ..core.logging import get_logger

logger = get_logger(__name__)


class GoogleDocsExporter:
    """Export reports to Google Docs."""
    
    def __init__(self):
        """Initialize Google Docs exporter."""
        self.settings = get_settings()
    
    async def create_comprehensive_report(
        self,
        analysis: AnalyzeResponse,
        include_appendix: bool = True,
        questionnaire_data: Optional[Dict[str, Any]] = None,
        video_analysis: Optional[Dict[str, Any]] = None
    ) -> Dict[str, str]:
        """Create comprehensive report with all data."""
        if self.settings.USE_VERTEX:
            return await self._create_google_doc_comprehensive(
                analysis, include_appendix, questionnaire_data, video_analysis
            )
        else:
            return self._create_local_comprehensive_report(
                analysis, include_appendix, questionnaire_data, video_analysis
            )
    
    async def create_report(
        self,
        analysis: AnalyzeResponse,
        include_appendix: bool = True
    ) -> Dict[str, str]:
        """Create Google Docs report.
        
        Args:
            analysis: Analysis response
            include_appendix: Include evidence appendix
            
        Returns:
            Document info with URL and ID
        """
        if self.settings.USE_VERTEX:
            return await self._create_google_doc(analysis, include_appendix)
        else:
            return self._create_local_report(analysis, include_appendix)
    
    def _create_local_report(
        self,
        analysis: AnalyzeResponse,
        include_appendix: bool
    ) -> Dict[str, str]:
        """Create comprehensive local HTML report.
        
        Args:
            analysis: Analysis response
            include_appendix: Include evidence appendix
            
        Returns:
            Document info
        """
        # Professional CSS styling
        css_style = """
        <style>
            body { font-family: 'Segoe UI', Arial, sans-serif; max-width: 900px; margin: 0 auto; padding: 20px; }
            h1 { color: #2c3e50; border-bottom: 3px solid #3498db; padding-bottom: 10px; }
            h2 { color: #34495e; margin-top: 30px; }
            table { border-collapse: collapse; width: 100%; margin: 20px 0; }
            th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
            th { background-color: #3498db; color: white; }
            tr:hover { background-color: #f5f5f5; }
            .metric-value { font-weight: bold; color: #2c3e50; }
            .recommendation { padding: 15px; margin: 20px 0; border-radius: 5px; }
            .recommend-invest { background-color: #d4edda; border: 1px solid #c3e6cb; }
            .recommend-follow { background-color: #fff3cd; border: 1px solid #ffeeba; }
            .recommend-pass { background-color: #f8d7da; border: 1px solid #f5c6cb; }
            .risk-high { color: #dc3545; font-weight: bold; }
            .risk-medium { color: #ffc107; font-weight: bold; }
            .risk-low { color: #28a745; }
            .evidence-item { background: #f8f9fa; padding: 10px; margin: 10px 0; border-left: 3px solid #3498db; }
            .score-badge { display: inline-block; padding: 5px 15px; border-radius: 20px; background: #3498db; color: white; }
        </style>
        """
        
        # Format KPIs nicely
        kpis_html = ""
        if analysis.kpis:
            kpis_data = [
                ("Annual Recurring Revenue (ARR)", f"${analysis.kpis.arr:,.0f}" if analysis.kpis.arr else "N/A"),
                ("Growth Rate", f"{analysis.kpis.growth_rate:.1f}x" if analysis.kpis.growth_rate else "N/A"),
                ("Gross Margin", f"{(analysis.kpis.gross_margin or 0) * 100:.1f}%" if analysis.kpis.gross_margin else "N/A"),
                ("Burn Rate", f"${analysis.kpis.burn_rate:,.0f}/month" if analysis.kpis.burn_rate else "N/A"),
                ("Runway", f"{analysis.kpis.runway_months} months" if analysis.kpis.runway_months else "N/A"),
                ("Logo Retention", f"{(analysis.kpis.logo_retention or 0) * 100:.1f}%" if analysis.kpis.logo_retention else "N/A"),
                ("Net Revenue Retention", f"{(analysis.kpis.nrr or 0) * 100:.1f}%" if analysis.kpis.nrr else "N/A")
            ]
            
            kpis_html = "<table><tr><th>Metric</th><th>Value</th></tr>"
            for metric, value in kpis_data:
                kpis_html += f'<tr><td>{metric}</td><td class="metric-value">{value}</td></tr>'
            kpis_html += "</table>"
        
        # Format risks
        risks_html = ""
        if analysis.risks:
            risks_html = "<ul>"
            for risk in analysis.risks:
                severity_class = "risk-high" if risk.severity >= 4 else "risk-medium" if risk.severity >= 3 else "risk-low"
                risks_html += f'<li>{risk.label} <span class="{severity_class}">(Severity: {risk.severity}/5)</span>'
                if risk.mitigation:
                    risks_html += f'<br><em>Mitigation: {risk.mitigation}</em>'
                risks_html += '</li>'
            risks_html += "</ul>"
        
        # Recommendation styling
        rec_class = f"recommend-{analysis.recommendation.value}"
        
        html_content = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <title>Investment Analysis - {analysis.startup_id}</title>
            <meta charset="UTF-8">
            {css_style}
        </head>
        <body>
            <h1>📊 {analysis.startup_id} Investment Analysis</h1>
            
            <div class="{rec_class} recommendation">
                <h2>📈 Recommendation: {analysis.recommendation.value.upper()}</h2>
                <p>Overall Score: <span class="score-badge">{analysis.score:.2%}</span></p>
            </div>
            
            <h2>📝 Executive Summary</h2>
            <ul>
                {''.join(f'<li>{s}</li>' for s in analysis.executive_summary)}
            </ul>
            
            <h2>💰 Key Metrics</h2>
            {kpis_html}
            
            <h2>⚠️ Risk Assessment</h2>
            {risks_html if risks_html else '<p>No significant risks identified.</p>'}
            
            {self._create_appendix(analysis.evidence) if include_appendix else ''}
            
            <hr style="margin-top: 50px;">
            <p style="text-align: center; color: #7f8c8d; font-size: 0.9em;">
                Generated on {analysis.timestamp.strftime('%Y-%m-%d %H:%M:%S')} | AnalystAI v1.0
            </p>
        </body>
        </html>
        """
        
        # Save locally
        from pathlib import Path
        import datetime
        
        report_dir = Path("data/reports")
        report_dir.mkdir(parents=True, exist_ok=True)
        
        # Include timestamp in filename
        timestamp = datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
        report_path = report_dir / f"{analysis.startup_id}_{timestamp}_report.html"
        report_path.write_text(html_content)
        
        logger.info(f"Created HTML report: {report_path}")
        
        return {
            "document_id": f"local_{analysis.startup_id}_{timestamp}",
            "document_url": f"file://{report_path.absolute()}"
        }
    
    def _create_appendix(self, evidence: List[Evidence]) -> str:
        """Create evidence appendix HTML.
        
        Args:
            evidence: Evidence list
            
        Returns:
            HTML appendix
        """
        if not evidence:
            return ""
        
        appendix = "<h2>Evidence Appendix</h2>\n<ul>\n"
        for e in evidence:
            appendix += f'<li><strong>{e.id}</strong> ({e.type.value}, {e.location}): {e.snippet}</li>\n'
        appendix += "</ul>"
        
        return appendix
    
    def _create_local_comprehensive_report(
        self,
        analysis: AnalyzeResponse,
        include_appendix: bool,
        questionnaire_data: Optional[Dict[str, Any]],
        video_analysis: Optional[Dict[str, Any]]
    ) -> Dict[str, str]:
        """Create comprehensive local HTML report with all data."""
        # First create the base report and get the HTML content by reading the file
        base_report = self._create_local_report(analysis, include_appendix)
        
        # Read the HTML content from the created file
        if base_report.get("document_url", "").startswith("file://"):
            filepath = base_report["document_url"].replace("file://", "")
            try:
                with open(filepath, "r") as f:
                    html = f.read()
            except Exception as e:
                logger.error(f"Failed to read base report: {e}")
                # Generate minimal HTML as fallback
                html = f"""<!DOCTYPE html>
                <html>
                <head><title>Analysis - {analysis.startup_id}</title></head>
                <body>
                <h1>Analysis for {analysis.startup_id}</h1>
                <p>Score: {analysis.score:.2%}</p>
                <p>Recommendation: {analysis.recommendation.value}</p>
                </body>
                </html>"""
        else:
            # Fallback HTML
            html = f"<html><body><h1>Analysis for {analysis.startup_id}</h1></body></html>"
        
        # Add questionnaire data section
        if questionnaire_data:
            questionnaire_html = "<h2>📋 Document Data</h2><table style='border-collapse: collapse; width: 100%; margin: 20px 0;'>"
            for key, value in questionnaire_data.items():
                # Handle complex values safely
                if isinstance(value, (dict, list)):
                    value_str = str(value)[:200] + "..." if len(str(value)) > 200 else str(value)
                else:
                    value_str = str(value)
                key_str = str(key).replace('_', ' ').title()
                questionnaire_html += f"<tr><td style='padding: 8px; border: 1px solid #ddd;'><strong>{key_str}</strong></td><td style='padding: 8px; border: 1px solid #ddd;'>{value_str}</td></tr>"
            questionnaire_html += "</table>"
            html = html.replace("</body>", f"{questionnaire_html}</body>")
        
        # Add video analysis section
        if video_analysis:
            video_html = "<h2>🎥 Video Analysis</h2>"
            if video_analysis.get("transcript"):
                transcript_preview = video_analysis['transcript'][:500] + "..." if len(video_analysis['transcript']) > 500 else video_analysis['transcript']
                video_html += f"<h3>Transcript</h3><p>{transcript_preview}</p>"
            if video_analysis.get("analysis"):
                va = video_analysis["analysis"]
                if isinstance(va, dict) and "founder_analysis" in va:
                    founder = va["founder_analysis"]
                    video_html += "<h3>Founder Assessment</h3><table style='border-collapse: collapse; width: 100%; margin: 20px 0;'>"
                    for key, value in founder.items():
                        if isinstance(value, (int, float)):
                            video_html += f"<tr><td style='padding: 8px; border: 1px solid #ddd;'><strong>{key.replace('_', ' ').title()}</strong></td><td style='padding: 8px; border: 1px solid #ddd;'>{value*100:.0f}%</td></tr>"
                    video_html += "</table>"
            html = html.replace("</body>", f"{video_html}</body>")
        
        # Save comprehensive report
        import os
        from datetime import datetime
        
        os.makedirs("data/reports", exist_ok=True)
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"data/reports/{analysis.startup_id}_{timestamp}_comprehensive_report.html"
        
        with open(filename, "w", encoding="utf-8") as f:
            f.write(html)
        
        logger.info(f"Created comprehensive report: {filename}")
        
        return {
            "document_url": f"file://{os.path.abspath(filename)}",
            "document_id": f"local_{timestamp}",
            "message": "Comprehensive report created locally"
        }
    
    async def _create_google_doc_comprehensive(
        self,
        analysis: AnalyzeResponse,
        include_appendix: bool,
        questionnaire_data: Optional[Dict[str, Any]],
        video_analysis: Optional[Dict[str, Any]]
    ) -> Dict[str, str]:
        """Create comprehensive Google Doc with all data."""
        try:
            from google.oauth2 import service_account
            from googleapiclient.discovery import build
            
            # Use service account credentials
            creds = service_account.Credentials.from_service_account_file(
                self.settings.GOOGLE_APPLICATION_CREDENTIALS,
                scopes=['https://www.googleapis.com/auth/documents']
            )
            
            service = build('docs', 'v1', credentials=creds)
            
            # Create document
            document = service.documents().create(body={
                'title': f'Investment Analysis - {analysis.startup_id}'
            }).execute()
            
            doc_id = document.get('documentId')
            
            # Build content
            requests = []
            content = f"INVESTMENT ANALYSIS REPORT\\n{analysis.startup_id}\\n\\n"
            content += f"Score: {analysis.investment_score:.1f}/100\\n"
            content += f"Recommendation: {analysis.recommendation}\\n\\n"
            
            # Add questionnaire data
            if questionnaire_data:
                content += "QUESTIONNAIRE DATA\\n"
                for key, value in questionnaire_data.items():
                    content += f"{key}: {value}\\n"
                content += "\\n"
            
            # Add video analysis
            if video_analysis:
                content += "VIDEO ANALYSIS\\n"
                if video_analysis.get("transcript"):
                    content += f"Transcript: {video_analysis['transcript'][:500]}...\\n"
                content += "\\n"
            
            # Insert content
            requests.append({
                'insertText': {
                    'location': {'index': 1},
                    'text': content
                }
            })
            
            service.documents().batchUpdate(
                documentId=doc_id,
                body={'requests': requests}
            ).execute()
            
            return {
                "document_url": f"https://docs.google.com/document/d/{doc_id}/edit",
                "document_id": doc_id,
                "message": "Comprehensive Google Doc created successfully"
            }
            
        except Exception as e:
            logger.error(f"Failed to create Google Doc: {e}")
            # Fallback to local report
            return self._create_local_comprehensive_report(
                analysis, include_appendix, questionnaire_data, video_analysis
            )
    
    async def _create_google_doc(
        self,
        analysis: AnalyzeResponse,
        include_appendix: bool
    ) -> Dict[str, str]:
        """Create actual Google Doc using Google Docs API.
        
        Args:
            analysis: Analysis response
            include_appendix: Include evidence appendix
            
        Returns:
            Document info with URL and ID
        """
        try:
            from google.oauth2 import service_account
            from googleapiclient.discovery import build
            from googleapiclient.errors import HttpError
            
            # Load credentials (requires service account JSON)
            creds_path = os.getenv('GOOGLE_APPLICATION_CREDENTIALS')
            if not creds_path:
                logger.warning("Google credentials not configured, using local report")
                return self._create_local_report(analysis, include_appendix)
            
            credentials = service_account.Credentials.from_service_account_file(
                creds_path,
                scopes=['https://www.googleapis.com/auth/documents']
            )
            
            # Build service
            service = build('docs', 'v1', credentials=credentials)
            
            # Create document
            document = service.documents().create(
                body={'title': f'Investment Analysis - {analysis.startup_id}'}
            ).execute()
            
            document_id = document.get('documentId')
            
            # Build requests for document content
            requests = self._build_doc_requests(analysis, include_appendix)
            
            # Update document
            service.documents().batchUpdate(
                documentId=document_id,
                body={'requests': requests}
            ).execute()
            
            return {
                "document_id": document_id,
                "document_url": f"https://docs.google.com/document/d/{document_id}/edit"
            }
            
        except ImportError:
            logger.warning("Google API client not installed")
            return self._create_local_report(analysis, include_appendix)
        except Exception as e:
            logger.error(f"Failed to create Google Doc: {str(e)}")
            return self._create_local_report(analysis, include_appendix)
    
    def _build_doc_requests(self, analysis: AnalyzeResponse, include_appendix: bool) -> list:
        """Build Google Docs API requests for document content.
        
        Args:
            analysis: Analysis response
            include_appendix: Include evidence appendix
            
        Returns:
            List of API requests
        """
        requests = []
        index = 1
        
        # Title
        requests.append({
            'insertText': {
                'location': {'index': index},
                'text': f'{analysis.startup_id} Investment Analysis\n\n'
            }
        })
        index += len(f'{analysis.startup_id} Investment Analysis\n\n')
        
        # Executive Summary
        requests.append({
            'insertText': {
                'location': {'index': index},
                'text': 'Executive Summary\n'
            }
        })
        index += len('Executive Summary\n')
        
        for point in analysis.executive_summary:
            requests.append({
                'insertText': {
                    'location': {'index': index},
                    'text': f'• {point}\n'
                }
            })
            index += len(f'• {point}\n')
        
        # Add more sections as needed...
        
        return requests
