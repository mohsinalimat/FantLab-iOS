import Foundation
import UIKit
import ALLKit
import FLStyle
import FLText
import FLKit
import FLModels
import YYWebImage

final class WorkReviewRatingLayoutSpec: ModelLayoutSpec<(Int, Int)> {
    override func makeNodeFrom(model: (Int, Int), sizeConstraints: SizeConstraints) -> LayoutNode {
        let titleString = "Оценка".attributed()
            .font(Fonts.system.regular(size: 9))
            .kern(-0.5)
            .foregroundColor(UIColor.lightGray)
            .make()
        
        let valueString: NSAttributedString
        
        let markColor = RatingColorRule.colorFor(rating: Float(model.0))
        
        if model.1 > 0 {
            valueString =
                String(model.0).attributed()
                    .font(Fonts.system.bold(size: 15))
                    .foregroundColor(markColor)
                    .make()
                +
                " +\(model.1)".attributed()
                    .font(Fonts.system.regular(size: 11))
                    .foregroundColor(UIColor.lightGray)
                    .baselineOffset(4)
                    .make()
        } else {
            valueString = String(model.0).attributed()
                .font(Fonts.system.bold(size: 15))
                .foregroundColor(markColor)
                .make()
        }
        
        let valueNode = LayoutNode(sizeProvider: valueString) { (label: UILabel, _) in
            label.numberOfLines = 0
            label.attributedText = valueString
        }
        
        let titleNode = LayoutNode(sizeProvider: titleString, config: { node in
            node.marginTop = 2
        }) { (label: UILabel, _) in
            label.numberOfLines = 0
            label.attributedText = titleString
        }
        
        return LayoutNode(children: [valueNode, titleNode], config: { node in
            node.marginLeft = 12
            node.flexDirection = .column
            node.alignItems = .center
        })
    }
}
