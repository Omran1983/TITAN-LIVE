import os
import sys

# Ensure we can import from CWD
sys.path.append(os.getcwd())

def test():
    print("[-] Loading environment...")
    from dotenv import load_dotenv
    load_dotenv()
    
    # Import internals to debug
    try:
        from citadel.integrations.github_app_auth import make_app_jwt, get_github_token, GITHUB_API
    except ImportError as e:
        print(f"[!] Import Error: {e}")
        return

    app_id = os.environ.get('GITHUB_APP_ID')
    pem = os.environ.get('GITHUB_APP_PRIVATE_KEY_PEM')
    owner = os.environ.get('GITHUB_OWNER')
    repo = os.environ.get('GITHUB_REPO')

    if not app_id or not pem:
        print("[!] Missing App ID or PEM.")
        return

    print("[-] Generating JWT to list installations...")
    try:
        jwt_token = make_app_jwt(app_id, pem)
    except Exception as e:
        print(f"[!] JWT Gen Failed: {e}")
        return

    import requests
    r = requests.get(f"{GITHUB_API}/app/installations", headers={
        "Authorization": f"Bearer {jwt_token}",
        "Accept": "application/vnd.github+json"
    })
    
    if r.status_code != 200:
        print(f"[!] Failed to list installations: {r.status_code} {r.text}")
    else:
        installs = r.json()
        print(f"[-] Found {len(installs)} installations:")
        for i in installs:
            print(f"    - Install ID: {i['id']} | Owner: {i['account']['login']}")
            # Use the first found installation for auto-fix
            with open("install_id.txt", "w") as f:
                f.write(str(i['id']))
            # Try to list accessible repositories for this installation if possible?
            # Require access token.
    
    print(f"\n[-] Attempting Auth for Owner='{owner}' Repo='{repo}'...")
    try:
        token = get_github_token()
        print(f"[+] SUCCESS! Token verified.")
        print(f"    Token: {token[:10]}... (expires in ~60m)")
    except Exception as e:
        print(f"[!] FAILURE: {e}")

if __name__ == "__main__":
    test()
