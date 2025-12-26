import subprocess

# Test the exact logic from runner.py
cwd = "F:\\AION-ZERO"

# The command that failed (nested powershell)
test_cmd_nested = "powershell -NoProfile -Command \"Write-Output ('CWD=' + (Get-Location).Path); python --version 2>&1 | ForEach-Object { Write-Output $_ }\""

# A simpler command
test_cmd_simple = "Write-Output 'Testing Simple output'; Get-Location; python --version"

def test(name, cmd):
    print(f"--- Testing {name} ---")
    print(f"Command: {cmd}")
    try:
        # runner.py uses this specific call structure:
        proc = subprocess.run(["powershell", "-NoProfile", "-Command", cmd], cwd=cwd, capture_output=True, text=True)
        print(f"Return Code: {proc.returncode}")
        print(f"STDOUT: [{proc.stdout}]")
        print(f"STDERR: [{proc.stderr}]")
    except Exception as e:
        print(f"Exception: {e}")
    print("\n")

if __name__ == "__main__":
    test("Nested PowerShell", test_cmd_nested)
    test("Simple Command", test_cmd_simple)
