import os
import sys
import hmac
import hashlib
import argparse

# -----------------------------------------------------------------------------
# AION-ZERO CRYPTOGRAPHIC WATERMARKER
# -----------------------------------------------------------------------------
# Signs code files to prove AION-ZERO authorship and detect tampering.
# -----------------------------------------------------------------------------

SECRET_KEY = os.environ.get("AION_SIGNING_KEY", "default-aion-zero-secret-key-change-me").encode()
SIG_PREFIX = "# AION-ZERO-SIG: "

def calculate_signature(content_bytes):
    """Generates HMAC-SHA256 signature of the content."""
    return hmac.new(SECRET_KEY, content_bytes, hashlib.sha256).hexdigest()

def sign_file(file_path):
    """Appends/Updates signature in the file."""
    if not os.path.exists(file_path):
        print(f"[ERROR] File not found: {file_path}")
        return False

    with open(file_path, 'rb') as f:
        content = f.read()

    # Split into lines to check for existing signature
    try:
        text = content.decode('utf-8')
        lines = text.splitlines(keepends=True)
    except UnicodeDecodeError:
        print(f"[SKIP] Binary file or non-utf8: {file_path}")
        return False

    # Remove existing signature if present (it's always the last line starting with prefix)
    clean_lines = [line for line in lines if not line.strip().startswith(SIG_PREFIX)]
    clean_content = "".join(clean_lines).encode('utf-8')

    # Calculate new signature based on CLEAN content
    sig = calculate_signature(clean_content)
    
    # Append new signature
    # Ensure newline before signature if needed
    final_content = clean_content
    if not final_content.endswith(b'\n'):
        final_content += b'\n'
    
    signature_line = f"{SIG_PREFIX}{sig}\n".encode('utf-8')
    final_content += signature_line

    with open(file_path, 'wb') as f:
        f.write(final_content)
    
    print(f"[SIGNED] {file_path} (Sig: {sig[:8]}...)")
    return True

def verify_file(file_path):
    """Verifies the signature of a file."""
    if not os.path.exists(file_path):
        print(f"[ERROR] File not found: {file_path}")
        return False

    with open(file_path, 'rb') as f:
        content = f.read()

    try:
        text = content.decode('utf-8')
        lines = text.splitlines(keepends=True)
    except UnicodeDecodeError:
        print(f"[SKIP] Binary file: {file_path}")
        return False

    # Find signature
    sig_line = None
    clean_lines = []
    
    for line in lines:
        if line.strip().startswith(SIG_PREFIX):
            sig_line = line.strip()
        else:
            clean_lines.append(line)
            
    if not sig_line:
        print(f"[UNSIGNED] {file_path}")
        return False
        
    extracted_sig = sig_line.replace(SIG_PREFIX, "").strip()
    clean_content = "".join(clean_lines).encode('utf-8')
    
    expected_sig = calculate_signature(clean_content)
    
    if hmac.compare_digest(extracted_sig, expected_sig):
        print(f"[VALID] {file_path}")
        return True
    else:
        print(f"[TAMPERED] {file_path} (Signature Mismatch)")
        return False

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("action", choices=["sign", "verify"], help="Action to perform")
    parser.add_argument("file", help="Target file path")
    args = parser.parse_args()

    if args.action == "sign":
        sign_file(args.file)
    elif args.action == "verify":
        verify_file(args.file)
