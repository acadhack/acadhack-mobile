/**
 * AcadHack Mobile Injector 💉
 * Handles DOM interaction for the Acadally WebView.
 */

(function () {
    // console.log("AcadHack Injector Loaded");

    const channel = window.AcadHackChannel;

    // === Helpers ===
    function log(msg) {
        if (channel) channel.postMessage(JSON.stringify({ type: 'LOG', message: msg }));
    }

    function extractOptions(cards) {
        return Array.from(cards).map((card, index) => {
            // New Selector (from config.py/scraper.py): 
            // label_el = card.find_element(By.CLASS_NAME, config.OPTION_LABEL_CLASS)
            // content_element = card.find_element(By.CLASS_NAME, "option-text")

            // Try to find text within .option-text OR fallback to card text
            const textEl = card.querySelector('.option-text');
            const text = textEl ? textEl.innerText.trim() : card.innerText.trim();

            return {
                index: index,
                text: text
            };
        });
    }

    // === Core Logic ===
    function checkPage() {
        // 1. Detect Question
        // Correct Selector from config.py: QUESTION_CLASS = "question"
        const questionTextEl = document.querySelector('.question');

        if (questionTextEl && !window._processedQuestion) {
            const questionText = questionTextEl.innerText.trim();

            // Correct Selector from config.py: OPTION_CARD_CLASS = "option-card"
            const optionCards = document.querySelectorAll('.option-card');

            if (optionCards.length > 0) {
                log("Question found: " + questionText);
                window._processedQuestion = questionText; // Prevent spamming

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

    // === Actions (Called from Flutter) ===
    window.AcadHack = {
        clickOption: function (index) {
            log("Clicking option index: " + index);
            const optionCards = document.querySelectorAll('.option-card');
            if (optionCards[index]) {
                optionCards[index].click();

                // config.py: ACTION_BUTTON_CLASS = "selected-btn"
                setTimeout(() => {
                    const submitBtn = document.querySelector('.selected-btn');
                    if (submitBtn) submitBtn.click();
                }, 500);
            }
        },

        resetProcessing: function () {
            window._processedQuestion = null;
        }
    };

    // === Loop ===
    setInterval(checkPage, 1000);

})();
