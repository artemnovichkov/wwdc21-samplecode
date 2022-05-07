/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Script that runs in the background of the browser.
*/
browser.runtime.onMessage.addListener((request) => {
    browser.storage.local.get((item) => {
        let wordReplacementCount = 0;
        if (Object.keys(item).length !== 0)
            wordReplacementCount = item.wordCountObj.wordCount;

        if (request.type == "Words replaced") {
            let wordCountObj = {
                wordCount: wordReplacementCount + request.count
            };

            browser.storage.local.set({wordCountObj});
        }

        if (request.type == "Word count request") {
            browser.runtime.sendMessage({type: "Word count response", count: wordReplacementCount});
        }
    });
});
