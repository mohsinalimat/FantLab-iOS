import Foundation
import UIKit
import RxSwift
import ALLKit
import FantLabUtils
import FantLabStyle
import FantLabModels
import FantLabText
import FantLabBaseUI
import FantLabLayoutSpecs
import FantLabStyle

final class WorkReviewsViewController: ListViewController {
    private let interactor: WorkReviewsInteractor
    private let reviewsCount: Int

    init(workId: Int, reviewsCount: Int) {
        self.interactor = WorkReviewsInteractor(workId: workId)
        self.reviewsCount = reviewsCount

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    private let sortSelectionControl = UISegmentedControl(items: ["Оценка", "Дата", "Рейтинг"])

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Отзывы (\(reviewsCount))"

        view.backgroundColor = UIColor.white

        adapter.collectionView.contentInset.top = 48

        do {
            sortSelectionControl.backgroundColor = UIColor.white
            sortSelectionControl.selectedSegmentIndex = 2
            Appearance.setup(segmentedControl: sortSelectionControl)
            view.addSubview(sortSelectionControl)
            sortSelectionControl.pinEdges(to: view.safeAreaLayoutGuide, top: 8, left: 16, bottom: .nan, right: 16)
        }

        do {
            adapter.scrollEvents.didScroll = { [weak self] scrollView in
                self?.isSortSelectionControlHidden = (scrollView.contentOffset.y + scrollView.adjustedContentInset.top) > 10
            }

            sortSelectionControl.all_setEventHandler(for: .valueChanged) { [weak self] in
                guard let strongSelf = self else { return }

                let selectedSegmentIndex = strongSelf.sortSelectionControl.selectedSegmentIndex

                let sort: ReviewsSort

                switch selectedSegmentIndex {
                case 0:
                    sort = .mark
                case 2:
                    sort = .rating
                default:
                    sort = .date
                }

                strongSelf.interactor.sort(by: sort)
            }
        }

        interactor.stateObservable
            .observeOn(SerialDispatchQueueScheduler(qos: .default))
            .map { [weak self] state -> [ListItem] in
                return self?.makeListItemsFrom(state: state) ?? []
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] items in
                self?.adapter.set(items: items)
            })
            .disposed(by: disposeBag)

        interactor.loadNextPage()
    }

    // MARK: -

    private var isSortSelectionControlHidden: Bool = false {
        didSet {
            guard isSortSelectionControlHidden != oldValue else {
                return
            }

            let alpha: CGFloat = isSortSelectionControlHidden ? 0 : 1
            let transform: CGAffineTransform = isSortSelectionControlHidden ? CGAffineTransform(translationX: 0, y: -40) : .identity

            UIView.animate(withDuration: 0.2, delay: 0, options: .beginFromCurrentState, animations: { [sortSelectionControl] in
                sortSelectionControl.alpha = alpha
                sortSelectionControl.transform = transform
            })
        }
    }

    private let loadingItemId = UUID().uuidString
    private let errorItemId = UUID().uuidString

    private func makeListItemsFrom(state: WorkReviewsInteractor.State) -> [ListItem] {
        var items: [ListItem] = state.reviews.enumerated().flatMap { (index, review) -> [ListItem] in
            let itemId = "review_" + String(review.id)

            let headerItem = ListItem(
                id: itemId + "_header",
                layoutSpec: WorkReviewHeaderLayoutSpec(model: review)
            )

            let textItem = ListItem(
                id: itemId + "_text",
                layoutSpec: WorkReviewTextLayoutSpec(model: review)
            )

            textItem.didSelect = { [weak self] cell, _ in
                CellSelection.scale(cell: cell, action: {
                    self?.open(review: review)
                })
            }

            if index == state.reviews.endIndex - 1 {
                textItem.willDisplay = { [weak self] _, _ in
                    self?.interactor.loadNextPage()
                }
            }

            let separatorItem = ListItem(
                id: itemId + "_separator",
                layoutSpec: ItemSeparatorLayoutSpec(model: Colors.separatorColor)
            )

            return [headerItem, textItem, separatorItem]
        }

        switch state.status {
        case .loading:
            let item = ListItem(id: loadingItemId, model: loadingItemId, layoutSpec: SpinnerLayoutSpec())

            items.append(item)
        case .error:
        break // TODO:
        case .idle:
            break
        }

        return items
    }

    private func open(review: WorkReviewModel) {
        AppRouter.shared.openReview(model: review)
    }
}