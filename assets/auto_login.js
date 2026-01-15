/**
 * AcadHack Auto-Login 🤖
 * Version: 3.0 (Polling + URL Check + Aggressive Events)
 */
(function () {
    console.log("AcadHack: Auto-Login v3 Loaded");

    const channel = window.AcadHackChannel;
    function log(msg) {
        console.log("AH_LOG: " + msg);
        if (channel) channel.postMessage(JSON.stringify({ type: 'LOG', message: msg }));
    }

    if (!window.AcadHackAuth) {
        window.AcadHackAuth = {
            login: function (user, pass) {
                log("Starting Auto-Login v3...");

                // Helper to dispatch React-friendly events
                function triggerInput(el, value) {
                    // Force focus first
                    el.focus();

                    // React Fiber internal hack - set old value first to trigger change detection
                    const nativeInputValueSetter = Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, "value").set;

                    // Get React's internal tracker
                    const tracker = el._valueTracker;
                    if (tracker) {
                        tracker.setValue(''); // Set to different value first
                    }

                    // Now set the actual value
                    nativeInputValueSetter.call(el, value);

                    // Dispatch input event (most important for React)
                    const inputEvent = new Event('input', { bubbles: true, cancelable: true });
                    el.dispatchEvent(inputEvent);

                    // Also dispatch change for good measure
                    const changeEvent = new Event('change', { bubbles: true });
                    el.dispatchEvent(changeEvent);

                    // Blur to complete the interaction cycle
                    el.blur();
                }

                if (window.AcadHackLoop) clearInterval(window.AcadHackLoop);

                // LOOP: Check for state every 1000ms
                window.AcadHackLoop = setInterval(() => {
                    const currentUrl = window.location.href;
                    // log("Loop Check: " + currentUrl); // Verbose Heartbeat

                    // 1. Login Page -> Username Phase
                    if (currentUrl.includes('/login')) {
                        const userField = document.getElementById('username');
                        // Ensure field exists and is NOT yet filled correctly
                        if (userField) {
                            // Check if value needs to be set (Resilient to React wiping it)
                            if (userField.value !== user) {
                                log("Enforcing Username Value...");
                                triggerInput(userField, user);
                            } else {
                                // Value is correct, check button
                                const btn = document.querySelector('button[type="submit"]');
                                if (btn && !btn.disabled) {
                                    log("Username Set & Button Ready -> Clicking Sign In...");
                                    btn.click();
                                    // Check if we moved to password phase is handled by next loop iteration
                                    // But we can pause a bit to avoid double clicks
                                    // Actually, let's just let the loop handle it
                                } else {
                                    // If button is still disabled, maybe trigger input again just in case
                                    // or just wait.
                                }
                            }
                        }
                    }

                    // 3. Login Page -> Password Phase (Detected by UI change)
                    // The URL might stay the same, but the DOM changes? 
                    // Usually Acadally keeps /login URL but swaps form.
                    // We need to detect if Password field exists.
                    const passField = document.getElementById('password');
                    if (passField && passField.offsetParent !== null) {
                        // Password Field Visible!
                        if (passField.value !== pass) {
                            log("Enforcing Password Value...");
                            triggerInput(passField, pass);
                        } else {
                            const btn = document.querySelector('button[type="submit"]');
                            // Ensure it's the Password Submit button (usually same button, just re-rendered)
                            if (btn && !btn.disabled) {
                                // Verify it's not the username button?
                                // If password field is present, username is likely hidden or we are in step 2.
                                log("Password Set & Button Ready -> Clicking Goal...");
                                btn.click();
                                // We can clear loop if we are sure? 
                                // Better to wait for URL change to /dashboard
                            }
                        }
                    }

                }, 1000); // Check every second

                // Safety: Stop checking after 60 seconds
                setTimeout(() => { if (window.AcadHackLoop) clearInterval(window.AcadHackLoop); }, 60000);
            }
        };
    }
})();
