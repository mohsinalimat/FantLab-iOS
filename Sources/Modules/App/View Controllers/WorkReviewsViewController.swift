import Foundation
import UIKit
import RxSwift
import RxRelay
import ALLKit
import FLKit
import FLStyle
import FLModels
import FLText
import FLUIKit
import FLLayoutSpecs
import FLStyle
import FLContentBuilders
import FLWebAPI

extension ReviewsSort: CustomStringConvertible {
    public var description: String {
        switch self {
        case .date:
            return "Дата"
        case .mark:
            return "Оценка"
        case .rating:
            return "Рейтинг"
        }
    }
}

final class WorkReviewsViewController: SegmentedListViewController<ReviewsSort, PagedDataStateContentBuilder<WorkReviewModel, WorkReviewsListContentBuilder>> {
    private let sortRelay = PublishRelay<ReviewsSort>()
    private let dataSource: PagedComboDataSource<WorkReviewModel>
    private let reviewsCount: Int
    private let reviewHeaderMode: WorkReviewHeaderMode

    init(workId: Int, reviewsCount: Int) {
        self.reviewsCount = reviewsCount

        do {
            let dataSourceObservable = sortRelay.asObservable().map { sort -> PagedDataSource<WorkReviewModel> in
                PagedDataSource(loadObservable: { page -> Observable<[WorkReviewModel]> in
                    AppServices.network.perform(request: GetWorkReviewsNetworkRequest(
                        workId: workId,
                        page: page,
                        sort: sort
                    ))
                })

            }
            
            dataSource = PagedComboDataSource(dataSourceObservable: dataSourceObservable)
        }

        reviewHeaderMode = .user

        super.init(defaultValue: .rating, contentBuilder: PagedDataStateContentBuilder(itemsContentBuilder: WorkReviewsListContentBuilder(headerMode: .user)))
    }

    init(userId: Int, reviewsCount: Int) {
        self.reviewsCount = reviewsCount

        do {
            let dataSourceObservable = sortRelay.asObservable().map { sort -> PagedDataSource<WorkReviewModel> in
                PagedDataSource(loadObservable: { page -> Observable<[WorkReviewModel]> in
                    AppServices.network.perform(request: GetUserReviewsNetworkRequest(
                        userId: userId,
                        page: page,
                        sort: sort
                    ))
                })

            }

            dataSource = PagedComboDataSource(dataSourceObservable: dataSourceObservable)
        }

        reviewHeaderMode = .work

        super.init(defaultValue: .rating, contentBuilder: PagedDataStateContentBuilder(itemsContentBuilder: WorkReviewsListContentBuilder(headerMode: .work, useSectionSeparatorStyle: true)))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    private let sortSelectionControl = UISegmentedControl(items: ["Оценка", "Дата", "Рейтинг"])

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Отзывы (\(reviewsCount))"

        contentBuilder.stateContentBuilder.errorContentBuilder.onRetry = { [weak self] in
            self?.dataSource.loadNextPage()
        }

        contentBuilder.onLastItemDisplay = { [weak self] in
            self?.dataSource.loadNextPage()
        }

        contentBuilder.itemsContentBuilder.singleReviewContentBuilder.onReviewUserTap = { userId in
            AppRouter.shared.openUserProfile(id: userId)
        }

        contentBuilder.itemsContentBuilder.singleReviewContentBuilder.onReviewWorkTap = { workId in
            AppRouter.shared.openWork(id: workId)
        }

        let headerMode = reviewHeaderMode

        contentBuilder.itemsContentBuilder.singleReviewContentBuilder.onReviewTextTap = { review in
            AppRouter.shared.openReview(model: review, headerMode: headerMode)
        }

        selectedSegmentObservable
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] sort in
                AppAnalytics.logReviewsSortChange(name: sort.description)

                self?.sortRelay.accept(sort)
            })
            .disposed(by: disposeBag)

        dataSource.stateObservable
            .subscribe(onNext: { [weak self] viewState in
                self?.apply(viewState: viewState)
            })
            .disposed(by: disposeBag)
    }
}
