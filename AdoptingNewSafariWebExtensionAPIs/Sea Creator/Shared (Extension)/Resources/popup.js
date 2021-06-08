/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Script that runs after clicking the extension's toolbar button.
*/
browser.runtime.onMessage.addListener((request) => {
    if (request.type == "Word count response") {
        let countDiv = document.getElementById("totalCount");
        countDiv.appendChild(document.createTextNode(`You've replaced ${request.count} words.`));
    }
});
browser.runtime.sendMessage({type: "Word count request"});

function replaceWords()
{
	browser.tabs.executeScript({file:"content.js"});
    window.close();
}

document.addEventListener("DOMContentLoaded", function() {
	document.getElementById("replaceWords").addEventListener("click", replaceWords);
});
