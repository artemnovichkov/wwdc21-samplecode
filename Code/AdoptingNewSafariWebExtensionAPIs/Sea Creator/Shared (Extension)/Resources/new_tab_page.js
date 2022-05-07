/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Configures the appearance of the extension's new tab override page.
*/

browser.runtime.onMessage.addListener((request) => {
    if (request.type == "Word count response") {
        let countDiv = document.getElementById("totalCount");

        if (!countDiv.hasChildNodes())
            countDiv.appendChild(document.createTextNode(`You've encountered ${request.count} sea creatures so far in your web surfing.`));
    }
});
browser.runtime.sendMessage({type: "Word count request"});
