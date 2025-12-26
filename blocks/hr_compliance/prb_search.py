"""
PRB Document Search System
Search PRB Volumes 1 & 2 and return exact citations
"""
import json
import re
from pathlib import Path
from typing import List, Dict, Tuple
import pdfplumber

class PRBDocumentSearch:
    def __init__(self, docs_dir: str = "F:/AION-ZERO/blocks/hr_compliance/docs"):
        self.docs_dir = Path(docs_dir)
        self.volume1_path = self.docs_dir / "PRB_2021_Volume1_General.pdf"
        self.volume2_path = self.docs_dir / "PRB_2026_Official_Report.pdf"
        
        # Load extracted data
        self.extracted_data_v2 = self._load_json("extracted_data.json")
        self.master_table = self._load_json("master_salary_table.json")
    
    def _load_json(self, filename: str) -> dict:
        """Load extracted JSON data"""
        path = self.docs_dir / filename
        if path.exists():
            with open(path, 'r', encoding='utf-8') as f:
                return json.load(f)
        return {}
    
    def search(self, query: str) -> List[Dict]:
        """
        Search both PRB volumes for query
        Returns list of results with page numbers and context
        """
        query_lower = query.lower()
        results = []
        
        # Search keywords
        keywords = self._extract_keywords(query_lower)
        
        # Search Volume 2 extracted data
        results.extend(self._search_volume2(keywords))
        
        # Search Volume 1 if needed
        if "salary" in keywords or "increment" in keywords or "16500" in keywords:
            results.extend(self._search_volume1(keywords))
        
        # Sort by relevance
        results.sort(key=lambda x: x.get('relevance', 0), reverse=True)
        
        return results[:10]  # Top 10 results
    
    def _extract_keywords(self, query: str) -> List[str]:
        """Extract search keywords from query"""
        # Remove common words
        stop_words = {'what', 'is', 'the', 'a', 'an', 'for', 'in', 'on', 'at', 'to', 'of'}
        words = query.split()
        keywords = [w for w in words if w not in stop_words and len(w) > 2]
        
        # Add number patterns
        numbers = re.findall(r'\d+[,\d]*', query)
        keywords.extend([n.replace(',', '') for n in numbers])
        
        return keywords
    
    def _search_volume2(self, keywords: List[str]) -> List[Dict]:
        """Search Volume 2 (Parastatal Bodies)"""
        results = []
        
        # Search key findings
        for finding in self.extracted_data_v2.get('key_findings', []):
            snippet = finding.get('snippet', '') + finding.get('text', '')
            snippet_lower = snippet.lower()
            
            # Count keyword matches
            matches = sum(1 for kw in keywords if kw in snippet_lower)
            
            if matches > 0:
                results.append({
                    'volume': 'Volume 2 (Parastatal Bodies)',
                    'page': finding.get('page'),
                    'type': finding.get('type', 'general'),
                    'text': snippet[:300],
                    'relevance': matches,
                    'pdf_path': str(self.volume2_path)
                })
        
        # Search salary tables
        for table in self.extracted_data_v2.get('salary_tables', []):
            table_text = str(table.get('data', ''))
            table_lower = table_text.lower()
            
            matches = sum(1 for kw in keywords if kw in table_lower)
            
            if matches > 0:
                results.append({
                    'volume': 'Volume 2 (Parastatal Bodies)',
                    'page': table.get('page'),
                    'type': 'salary_table',
                    'text': f"Salary/Allowance table found (Table {table.get('table_index', 0)})",
                    'relevance': matches,
                    'pdf_path': str(self.volume2_path)
                })
        
        return results
    
    def _search_volume1(self, keywords: List[str]) -> List[Dict]:
        """Search Volume 1 (General Conditions)"""
        results = []
        
        # Search increment rules
        for rule in self.master_table.get('increment_rules', []):
            snippet = rule.get('snippet', '')
            snippet_lower = snippet.lower()
            
            matches = sum(1 for kw in keywords if kw in snippet_lower)
            
            if matches > 0:
                results.append({
                    'volume': 'Volume 1 (General Conditions)',
                    'page': rule.get('page'),
                    'type': 'increment_rule',
                    'text': snippet[:300],
                    'relevance': matches,
                    'pdf_path': str(self.volume1_path)
                })
        
        # Check salary floor
        salary_floor = self.master_table.get('salary_floor')
        if salary_floor and any(kw in ['salary', 'floor', 'minimum', '16500'] for kw in keywords):
            results.append({
                'volume': 'Volume 1 (General Conditions)',
                'page': salary_floor.get('page'),
                'type': 'salary_floor',
                'text': salary_floor.get('context', 'Rs 16,500 minimum salary floor'),
                'relevance': 5,  # High relevance
                'pdf_path': str(self.volume1_path)
            })
        
        return results
    
    def get_page_text(self, pdf_path: str, page_num: int) -> str:
        """Extract full text from specific page"""
        try:
            with pdfplumber.open(pdf_path) as pdf:
                if 0 < page_num <= len(pdf.pages):
                    return pdf.pages[page_num - 1].extract_text()
        except Exception as e:
            return f"Error extracting page: {e}"
        return ""

# Example usage
if __name__ == "__main__":
    searcher = PRBDocumentSearch()
    
    # Test queries
    queries = [
        "What is the salary floor for 2026?",
        "increment eligibility rules",
        "Rs 16,500 minimum salary",
        "long service increment"
    ]
    
    for query in queries:
        print(f"\n{'='*60}")
        print(f"Query: {query}")
        print(f"{'='*60}")
        
        results = searcher.search(query)
        
        if results:
            for i, result in enumerate(results, 1):
                print(f"\n{i}. {result['volume']} - Page {result['page']}")
                print(f"   Type: {result['type']}")
                print(f"   Text: {result['text'][:200]}...")
        else:
            print("No results found")
