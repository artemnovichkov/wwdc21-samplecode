/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The content blocker.
*/

import MailKit

class ContentBlocker: NSObject, MEContentBlocker {
    
    static let shared = ContentBlocker()
    
    func contentRulesJSON() -> Data {
        // Read in the JSON file that contains the content blocking
        // rules and return it as data. The example rules file uses CSS
        // to hide all URLs that link to example.com.
        //
        // These rules are the same as Safari content blockers use.
        // For more information about creating content blocking rules, see:
        // https://developer.apple.com/documentation/safariservices/creating_a_content_blocker
        guard let url = Bundle.main.url(forResource: "ContentBlockerRules", withExtension: "json") else { return Data() }
        guard let data = try? Data(contentsOf: url) else { return Data() }
        
        return data
    }

}

