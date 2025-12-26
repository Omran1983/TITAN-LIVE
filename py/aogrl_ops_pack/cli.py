def summarize():
    import argparse, requests, subprocess
    parser = argparse.ArgumentParser()
    parser.add_argument("url")
    parser.add_argument("--llm", default="llama3")
    args = parser.parse_args()
    
    print(f"🧠 Summarizing with {args.llm}: {args.url}")
    try:
        resp = requests.get(args.url, timeout=10)
        text = resp.text[:10000]  # Limit size
    except Exception as e:
        print(f"❌ Failed to fetch: {e}")
        return

    try:
        result = subprocess.run(
            ["ollama", "run", args.llm],
            input=f"summarize this:\n{text}",
            text=True, capture_output=True, timeout=30
        )
        print("📝 Summary:\n")
        print(result.stdout.strip())
    except Exception as e:
        print(f"❌ Ollama error: {e}")
