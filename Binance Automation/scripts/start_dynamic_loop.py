import time, schedule
from services.dyn_bot import run_once

def main():
    run_once()                      # run immediately
    schedule.every(3).minutes.do(run_once)  # change cadence if you like
    while True:
        schedule.run_pending()
        time.sleep(5)

if __name__ == "__main__":
    main()
