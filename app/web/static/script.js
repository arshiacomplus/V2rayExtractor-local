document.addEventListener('DOMContentLoaded', () => {
    const scrapeForm = document.getElementById('scrape-form');
    const scrapeBtn = document.getElementById('scrape-btn');
    const btnText = scrapeBtn.querySelector('.btn-text');
    const urlsInput = document.getElementById('urls-input');
    const resultsSection = document.getElementById('results-section');
    const resultsOutput = document.getElementById('results-output');
    const saveBtn = document.getElementById('save-btn');
    scrapeForm.addEventListener('submit', async (event) => {
        event.preventDefault();
        scrapeBtn.disabled = true;
        btnText.textContent = 'Scraping...';
        resultsOutput.value = '';
        resultsSection.style.display = 'block';
        try {
            const formData = new FormData(scrapeForm);
            const response = await fetch('/api/scrape', {
                method: 'POST',
                body: formData,
            });
            const result = await response.json();
            if (!response.ok) {
                throw new Error(result.detail || 'An unknown error occurred.');
            }
            const configsText = result.configs.join('\n');
            resultsOutput.value = `✅ Found ${result.count} working configs:\n\n${configsText}`;
            if (result.count > 0) {
                saveBtn.style.display = 'block';
            } else {
                saveBtn.style.display = 'none';
                resultsOutput.value = 'ℹ️ No working configs found from the provided links.';
            }
        } catch (error) {
            resultsOutput.value = `❌ Error: ${error.message}`;
            saveBtn.style.display = 'none';
        } finally {
            scrapeBtn.disabled = false;
            btnText.textContent = 'Scrape & Test';
        }
    });
    saveBtn.addEventListener('click', () => {
        const content = resultsOutput.value;
        const blob = new Blob([content], { type: 'text/plain;charset=utf-8' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        const timestamp = new Date().toISOString().slice(0, 19).replace('T', '_').replace(/:/g, '-');
        a.download = `v2ray-configs_${timestamp}.txt`;
        a.href = url;
        a.click();
        URL.revokeObjectURL(url);
    });
});