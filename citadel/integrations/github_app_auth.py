
import os
import time
import jwt  # PyJWT
import requests

GITHUB_API = "https://api.github.com"

def _read_pem(path: str) -> str:
    """Read the PEM file content."""
    # If path is raw content (starts with -----BEGIN), return it
    if path.strip().startswith("-----BEGIN"):
        return path
        
    if not os.path.exists(path):
        raise FileNotFoundError(f"[AUTH] PEM file not found at: {path}")
        
    with open(path, "r", encoding="utf-8") as f:
        return f.read()

def make_app_jwt(app_id: str, pem_path: str) -> str:
    """Generate a JWT for the GitHub App."""
    private_key = _read_pem(pem_path)
    now = int(time.time())
    payload = {
        "iat": now - 30,
        "exp": now + (9 * 60),  # GitHub requires <= 10 minutes
        "iss": app_id,
    }
    
    # Encode returns bytes in older pyjwt, string in newer.
    # We want string.
    token = jwt.encode(payload, private_key, algorithm="RS256")
    return token.decode("utf-8") if isinstance(token, bytes) else token

def get_installation_id(app_jwt: str, owner: str, repo: str) -> int:
    """Find installation ID for a specific repo."""
    url = f"{GITHUB_API}/repos/{owner}/{repo}/installation"
    r = requests.get(url, headers={
        "Authorization": f"Bearer {app_jwt}",
        "Accept": "application/vnd.github+json",
    }, timeout=30)
    
    if r.status_code == 404:
        raise ValueError(f"[AUTH] App not installed on repo: {owner}/{repo}")
        
    r.raise_for_status()
    return int(r.json()["id"])

def get_installation_token(app_jwt: str, installation_id: int) -> str:
    """Exchange JWT+InstallID for an Access Token."""
    url = f"{GITHUB_API}/app/installations/{installation_id}/access_tokens"
    r = requests.post(url, headers={
        "Authorization": f"Bearer {app_jwt}",
        "Accept": "application/vnd.github+json",
    }, timeout=30)
    r.raise_for_status()
    return r.json()["token"]

def get_github_token(owner: str = None, repo: str = None) -> str:
    """
    Main entry point to get a valid GitHub token.
    Reads from GITHUB_APP_ID and GITHUB_APP_PRIVATE_KEY_PEM env vars.
    """
    app_id = os.environ.get("GITHUB_APP_ID")
    pem_path = os.environ.get("GITHUB_APP_PRIVATE_KEY_PEM")
    
    if not app_id or not pem_path:
        # Fallback to legacy token if App config missing
        legacy = os.environ.get("GITHUB_TOKEN") or os.environ.get("GITHUB_PAT")
        if legacy:
            return legacy
        raise ValueError("[AUTH] Missing GITHUB_APP_ID/PEM and no GITHUB_TOKEN fallback found.")

    app_jwt = make_app_jwt(app_id, pem_path)

    # Prefer direct installation ID if known (faster)
    installation_id = os.environ.get("GITHUB_APP_INSTALLATION_ID")
    
    if installation_id:
        inst_id = int(installation_id)
    else:
        if not owner or not repo:
             # Try to infer from env or git config? For now require args.
             # Using a default env var if set
             owner = owner or os.environ.get("GITHUB_OWNER")
             repo = repo or os.environ.get("GITHUB_REPO")
             
             if not owner or not repo:
                 raise ValueError("[AUTH] Need owner/repo to find Installation ID (or set GITHUB_APP_INSTALLATION_ID)")
                 
        inst_id = get_installation_id(app_jwt, owner, repo)

    return get_installation_token(app_jwt, inst_id)
