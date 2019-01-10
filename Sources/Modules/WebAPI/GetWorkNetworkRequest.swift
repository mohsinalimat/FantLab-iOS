import Foundation
import FantLabUtils
import FantLabModels

public final class GetWorkNetworkRequest: NetworkRequest {
    public typealias ModelType = WorkModel

    private let workId: Int

    public init(workId: Int) {
        self.workId = workId
    }

    public func makeURLRequest() -> URLRequest {
        return URLRequest(url: URL(string: "https://\(Hosts.api)/work/\(workId)/extended")!)
    }

    public func parse(response: URLResponse, data: Data) throws -> WorkModel {
        guard let json = JSON(jsonData: data) else {
            throw NetworkError.invalidJSON
        }

        return WorkModel(
            id: json.work_id.intValue,
            name: json.work_name.stringValue,
            origName: json.work_name_orig.stringValue,
            year: json.work_year.intValue,
            imageURL: URL.from(string: json.image.stringValue),
            workType: json.work_type.stringValue,
            publishStatuses: json.publish_statuses.array.map({ $0.stringValue }),
            rating: json.rating.rating.floatValue,
            votes: json.rating.voters.intValue,
            reviewsCount: json.val_responsecount.intValue,
            descriptionText: json.work_description.stringValue,
            descriptionAuthor: json.work_description_author.stringValue,
            notes: json.work_notes.stringValue,
            linguisticAnalysis: json.la_resume.array.map({ $0.stringValue }),
            authors: json.authors.array.map({
                WorkModel.AuthorModel(
                    id: $0.id.intValue,
                    name: $0.name.stringValue,
                    type: $0.type.stringValue,
                    isOpened: $0.is_opened.boolValue
                )
            }),
            children: json.children.array.map({
                WorkModel.ChildWorkModel(
                    id: $0.work_id.intValue,
                    name: $0.work_name.stringValue,
                    origName: $0.work_name_orig.stringValue,
                    nameBonus: $0.work_name_bonus.stringValue,
                    rating: $0.val_midmark_by_weight.floatValue,
                    votes: $0.val_voters.intValue,
                    workType: $0.work_type.stringValue,
                    workTypeKey: $0.work_type_name.stringValue,
                    publishStatus: $0.publish_status.stringValue,
                    isPublished: $0.work_published.boolValue,
                    year: $0.work_year.intValue,
                    deepLevel: $0.deep.intValue,
                    plus: $0.plus.boolValue
                )
            }),
            parents: json.parents.cycles.array.map({
                $0.array.map({
                    WorkModel.ParentWorkModel(
                        id: $0.work_id.intValue,
                        name: $0.work_name.stringValue,
                        workType: $0.work_type.stringValue
                    )
                })
            }),
            classificatory: json.classificatory.genre_group.array.map({
                WorkModel.GenreGroupModel(
                    title: $0.label.stringValue,
                    genres: $0.genre.array.map({
                        parseGenre(json: $0)
                    })
                )
            }),
            awards: parseAwards(json: json.awards.win.array + json.awards.nom.array)
        )
    }

    private func parseAwards(json: [JSON]) -> [WorkModel.AwardModel] {
        let jsonTable = Dictionary(grouping: json) { $0.award_id.stringValue }

        let awards = jsonTable.map { (_, group) in
            WorkModel.AwardModel(
                id: group[0].award_id.intValue,
                name: group[0].award_name.stringValue,
                rusName: group[0].award_rusname.stringValue,
                isOpen: group[0].award_is_opened.boolValue,
                iconURL: URL.from(string: group[0].award_icon.stringValue),
                contests: group.map({
                    WorkModel.AwardModel.ContestModel(
                        id: $0.contest_id.intValue,
                        year: $0.contest_year.intValue,
                        name: $0.nomination_rusname.string ?? $0.nomination_name.stringValue,
                        isWin: $0.cw_is_winner.boolValue
                    )
                }).sorted(by: { (x, y) -> Bool in
                    x.year < y.year
                })
            )
        }

        return awards.sorted(by: { (x, y) -> Bool in
            (x.rusName.nilIfEmpty ?? x.name).localizedCaseInsensitiveCompare(y.rusName.nilIfEmpty ?? y.name) == .orderedAscending
        })
    }

    private func parseGenre(json: JSON) -> WorkModel.GenreGroupModel.GenreModel {
        return WorkModel.GenreGroupModel.GenreModel(
            id: json.genre_id.intValue,
            label: json.label.stringValue,
            votes: json.votes.intValue,
            percent: json.percent.floatValue,
            genres: json.genre.array.map({
                parseGenre(json: $0)
            })
        )
    }
}
