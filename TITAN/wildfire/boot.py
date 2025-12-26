import os
import sys

# Ensure project root is in path
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.append(PROJECT_ROOT)

from wildfire.core.dispatcher import WildfireDispatcher

def main():
    print(">>> TITAN v2.0 'Wildfire' System Boot <<<")
    print(f"Root: {PROJECT_ROOT}")
    
    # Initialize Dispatcher
    try:
        dispatcher = WildfireDispatcher()
        print(f"Loaded {len(dispatcher.manifests)} Agent Manifests.")
        
        # Start Loop
        dispatcher.run_loop()
    except KeyboardInterrupt:
        print("\nShutdown.")
    except Exception as e:
        print(f"Fatal Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
