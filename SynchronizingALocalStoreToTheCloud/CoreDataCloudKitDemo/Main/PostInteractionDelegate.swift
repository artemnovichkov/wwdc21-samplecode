/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The interaction protocol between the MainViewController and DetailViewController.
*/

protocol PostInteractionDelegate: AnyObject {
    /**
     When the detail view controller has finished an edit, it calls didUpdatePost for the delegate (the main view controller) to update the UI.
     
     When deleting a post, pass nil for post.
     */
    func didUpdatePost(_ post: Post?, shouldReloadRow: Bool)
    
    /**
     UISplitViewController can show the detail view controller when it is appropriate.
     
     In that case main and detail view controllers may not be connected yet.
     
     So in the detail view controller’s willAppear, call this method so that the main view controller has a chance to build up the connection.
     */
    func willShowDetailViewController(_ controller: DetailViewController)
}
