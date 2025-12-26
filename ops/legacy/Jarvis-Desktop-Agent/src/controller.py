import time

import pyautogui

pyautogui.FAILSAFE = True  # Move mouse to top-left to abort

def move_and_click(x: int, y: int, delay: float = 0.5) -> None:
    print(f"[controller] Moving to ({x}, {y}) and clicking")
    pyautogui.moveTo(x, y, duration=0.4)
    time.sleep(delay)
    pyautogui.click()

def type_text(text: str, delay: float = 0.05) -> None:
    print(f"[controller] Typing: {text!r}")
    pyautogui.write(text, interval=delay)

if __name__ == "__main__":
    print("[controller] This module is not meant to be run directly.")
