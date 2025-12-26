"""
PRB Compliance Assistant - Streamlit UI
Search PRB documents and validate employee data
"""
import streamlit as st
import sys
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent))

from prb_search import PRBDocumentSearch

st.set_page_config(
    page_title="PRB Compliance Assistant",
    page_icon="📋",
    layout="wide"
)

# Initialize search system
@st.cache_resource
def get_searcher():
    return PRBDocumentSearch()

searcher = get_searcher()

# Header
st.title("📋 PRB-2026 Compliance Assistant")
st.markdown("Search official PRB documents and validate employee compliance")

# Tabs
tab1, tab2 = st.tabs(["🔍 Search PRB Documents", "✅ Validate Employees"])

# Tab 1: Document Search
with tab1:
    st.header("Search PRB Volumes 1 & 2")
    
    query = st.text_input(
        "Ask a question about PRB-2026 rules:",
        placeholder="e.g., What is the minimum salary for 2026?"
    )
    
    if st.button("Search", type="primary"):
        if query:
            with st.spinner("Searching PRB documents..."):
                results = searcher.search(query)
            
            if results:
                st.success(f"Found {len(results)} results")
                
                for i, result in enumerate(results, 1):
                    with st.expander(f"📄 {result['volume']} - Page {result['page']}", expanded=(i==1)):
                        col1, col2 = st.columns([3, 1])
                        
                        with col1:
                            st.markdown(f"**Type:** {result['type'].replace('_', ' ').title()}")
                            st.markdown(f"**Content:**")
                            st.info(result['text'])
                        
                        with col2:
                            st.metric("Page", result['page'])
                            st.metric("Relevance", f"{result['relevance']}/5")
                            
                            if st.button(f"View Full Page", key=f"view_{i}"):
                                page_text = searcher.get_page_text(
                                    result['pdf_path'],
                                    result['page']
                                )
                                st.text_area(
                                    f"Full text - Page {result['page']}",
                                    page_text,
                                    height=300
                                )
            else:
                st.warning("No results found. Try different keywords.")
        else:
            st.warning("Please enter a search query")

# Tab 2: Employee Validation
with tab2:
    st.header("Validate Employee Compliance")
    st.info("Upload employee CSV to check PRB-2026 compliance")
    
    uploaded_file = st.file_uploader(
        "Upload Employee Data (CSV)",
        type=['csv'],
        help="CSV should include: name, salary, performance_status, increment_proposed"
    )
    
    if uploaded_file:
        st.success("File uploaded! Validation coming soon...")
        st.markdown("**Next:** Run validation against PRB-2026 rules")

# Sidebar
with st.sidebar:
    st.header("📚 PRB Resources")
    
    st.markdown("**Available Documents:**")
    st.markdown("- Volume 1: General Conditions")
    st.markdown("- Volume 2: Parastatal Bodies")
    
    st.divider()
    
    st.markdown("**Quick Searches:**")
    if st.button("Salary Floor"):
        st.session_state['query'] = "What is the minimum salary floor?"
    if st.button("Increment Rules"):
        st.session_state['query'] = "increment eligibility rules"
    if st.button("Long Service Increment"):
        st.session_state['query'] = "long service increment"
    
    st.divider()
    
    st.markdown("**System Status:**")
    st.success("✅ PRB Volumes loaded")
    st.success("✅ Search engine ready")
