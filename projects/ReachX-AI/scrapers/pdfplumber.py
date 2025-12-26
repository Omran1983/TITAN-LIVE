# Local stub for pdfplumber
# Goal: let construction_scraper.py run without the real pdfplumber package.
# It returns an "empty" PDF so CIDB parsing is effectively skipped.

class DummyPage:
    def extract_text(self):
        # No text – caller will just get empty results
        return ""

class DummyPDF:
    def __init__(self, *args, **kwargs):
        # No pages – loop over pages does nothing
        self.pages = []

    def __enter__(self):
        print("[pdfplumber stub] open() called – returning empty PDF (no CIDB data).")
        return self

    def __exit__(self, exc_type, exc, tb):
        pass

def open(*args, **kwargs):
    # Mimic pdfplumber.open(...)
    return DummyPDF()
