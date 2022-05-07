/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A UITableViewCell subclass that implements UICollectionViewDelegate and UICollectionViewDataSource to present the tags of the current post.
*/

import UIKit

class TagCollectionCell: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource {
    @IBOutlet weak var collectionView: UICollectionView!
    private var _post: Post?
    var post: Post? {
        get {
            return _post
        }
        set {
            _post = newValue
            sortTags()
        }
    }
    var sortedTags: [Tag]?
    
    /**
     Sort tags alphabetically.
     */
    fileprivate func sortTags() {
        if let tags = _post?.tags,
            let tagsArray = tags.allObjects as? [Tag] {
            sortedTags = tagsArray.sorted(by: { (tag1, tag2) -> Bool in
                guard let name1 = tag1.name else {
                    fatalError("###\(#function): Tag is missing a name! \(tag1)")
                }
                guard let name2 = tag2.name else {
                    fatalError("###\(#function): Tag is missing a name! \(tag2)")
                }
                
                return name1.compare(name2) == .orderedAscending
            })
        }
    }
    
    /**
     The label font, used to calculate the tag text size.
     */
    private var tagLabelFont: UIFont!
    
    /**
     Create a cell and grab the font.
     
     Dequeueing a cell triggers collectionView data loading, but there is no data then so the load should end quickly.
     
     The view controller should call collectionView.reloadData when the data is ready.
     */
    override func awakeFromNib() {
        super.awakeFromNib()

        guard tagLabelFont == nil else { return }
        
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "tagCVCell", for: IndexPath(item: 0, section: 0)) as? TagCVCell
        tagLabelFont = cell?.tagLabel.font ?? UIFont.systemFont(ofSize: 17)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let post = post, let tags = post.tags else { return 0 }
        return tags.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "tagCVCell", for: indexPath) as? TagCVCell else {
            fatalError("###\(#function): Failed to dequeue TagCVCell! Check the cell reusable identifier in Main.storyboard.")
        }
        guard let tag = sortedTags?[indexPath.row] else { return cell }
        
        cell.tagLabel.text = tag.name
        cell.tagLabel.textColor = tag.color
        return cell
    }
    
    @objc(collectionView:layout:sizeForItemAtIndexPath:)
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        sortTags()
        guard let tag = sortedTags?[indexPath.item] else {
            fatalError("###\(#function): Failed to retrieve a tag from post.tags at: \(indexPath.item)")
        }
        return TagLabel.sizeOf(text: tag.name!, font: tagLabelFont)
    }
}
