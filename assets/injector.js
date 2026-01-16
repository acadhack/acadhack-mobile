/**
 * AcadHack Mobile Injector 💉
 * Handles DOM interaction for the Acadally WebView.
 */

(function () {
    if (window._acadHackInitialized) {
        console.log("AH_LOG: Injector already running, skipping init");
        return;
    }
    window._acadHackInitialized = true;

    console.log("AcadHack Injector Loaded 💉");

    const channel = window.AcadHackChannel;

    // === Helpers ===
    function log(msg) {
        console.log("AH_LOG: " + msg);
        if (channel) channel.postMessage(JSON.stringify({ type: 'LOG', message: msg }));
    }

    log("Injector Initialized at " + window.location.href);

    function extractOptions(cards) {
        return Array.from(cards).map((card, index) => {
            // Extract the option label (A, B, C, D)
            const labelEl = card.querySelector('.option-label-box');
            const label = labelEl ? labelEl.innerText.trim() : String.fromCharCode(65 + index);

            // Extract the option text
            const textEl = card.querySelector('.option-text');
            const text = textEl ? textEl.innerText.trim() : card.innerText.trim();

            return {
                index: index,
                label: label,
                text: text
            };
        });
    }

    // === Core Logic ===
    function checkPage() {
        // Detect Question
        const questionBox = document.querySelector('.question-box');

        if (questionBox) {
            const questionEl = questionBox.querySelector('.question p');
            if (questionEl) {
                const questionText = questionEl.innerText.trim();

                // Only process if it's a new question
                if (window._processedQuestion !== questionText) {
                    const optionCards = questionBox.querySelectorAll('.option-card');

                    if (optionCards.length > 0) {
                        log("New Question found: " + questionText.substring(0, 50) + "...");
                        window._processedQuestion = questionText;

                        const options = extractOptions(optionCards);

                        if (channel) {
                            channel.postMessage(JSON.stringify({
                                type: 'QUESTION_FOUND',
                                question: questionText,
                                options: options
                            }));
                        }
                    }
                }
            }
        }
    }

    // === Actions (Called from Flutter) ===
    window.AcadHack = {
        clickOption: function (index) {
            log("Clicking option index: " + index);
            const optionCards = document.querySelectorAll('.option-card');
            if (optionCards[index]) {
                optionCards[index].click();

                // After selecting option, click the Next Question button
                setTimeout(() => {
                    const nextBtn = document.querySelector('.next-btn');
                    if (nextBtn && !nextBtn.disabled) {
                        log("Clicking Next Question button");
                        nextBtn.click();
                        // Reset processed question so next one can be detected
                    } else {
                        log("Next button not found or disabled");
                    }
                }, 800);
            }
        },

        resetProcessing: function () {
            window._processedQuestion = null;
            log("Processing Reset");
        }
    };

    // === Loop ===
    setInterval(checkPage, 1000);
    log("Check loop started");

})();
