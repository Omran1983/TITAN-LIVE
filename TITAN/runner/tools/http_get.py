
import requests
import hashlib
import ipaddress
import socket
from urllib.parse import urlparse

def is_private_ip(hostname):
    try:
        ip = socket.gethostbyname(hostname)
        return ipaddress.ip_address(ip).is_private
    except:
        return False

def run_http_get(args, allowlist):
    # args: url, headers, timeout_seconds, max_bytes
    url = args.get("url")
    if not url:
        return {"ok": False, "error": "Missing URL"}

    # 1. SECURITY CHECKS
    parsed = urlparse(url)
    if parsed.scheme not in ["http", "https"]:
        return {"ok": False, "error": "Scheme must be http or https"}
    
    # Check Private IP (SSRF)
    policy = allowlist.get("tools", {}).get("http.get", {})
    if policy.get("deny_private_ips", True):
        if is_private_ip(parsed.hostname):
            return {"ok": False, "error": "Private IP access denied"}

    # Check Domains
    allowed = policy.get("allow_domains", [])
    if "*" not in allowed:
        # Simple domain check (suffix match)
        domain = parsed.hostname
        if not any(domain.endswith(d) for d in allowed):
            return {"ok": False, "error": f"Domain {domain} not in allowlist"}

    # 2. EXECUTE
    timeout = min(args.get("timeout_seconds", 30), policy.get("timeout_seconds", 30))
    max_bytes = min(args.get("max_bytes", 1000000), policy.get("max_bytes", 1000000))
    headers = args.get("headers", {"User-Agent": "TitanRunner/1.0"})

    try:
        with requests.get(url, headers=headers, timeout=timeout, stream=True, allow_redirects=True) as r:
            # Check Status
            status_code = r.status_code
            content_type = r.headers.get("Content-Type", "")
            final_url = r.url
            
            # Read Strict Max Bytes
            content = b""
            for chunk in r.iter_content(chunk_size=4096):
                content += chunk
                if len(content) > max_bytes:
                    return {"ok": False, "error": f"Max bytes exceeded ({max_bytes})"}
            
            # Hash
            sha256 = hashlib.sha256(content).hexdigest()
            
            # Text decode if possible
            text = ""
            if "text" in content_type or "json" in content_type or "xml" in content_type:
                try:
                    text = content.decode("utf-8")
                except:
                    text = "[Binary or Non-UTF8]"

            return {
                "ok": True,
                "status_code": status_code,
                "final_url": final_url,
                "content_type": content_type,
                "bytes": len(content),
                "text": text,
                "sha256": sha256
            }
            
    except Exception as e:
        return {"ok": False, "error": str(e)}
