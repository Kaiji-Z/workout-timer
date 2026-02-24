from playwright.sync_api import sync_playwright
import time

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    page = browser.new_page(viewport={"width": 390, "height": 844})  # iPhone 14 Pro size
    
    # Navigate to the app
    page.goto('http://localhost:8080')
    page.wait_for_load_state('networkidle')
    time.sleep(2)  # Wait for animations
    
    # Take screenshot
    page.screenshot(path='screenshot.png', full_page=True)
    print("Screenshot saved to screenshot.png")
    
    browser.close()
