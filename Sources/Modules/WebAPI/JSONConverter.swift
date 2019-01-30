import Foundation
import FantLabUtils
import FantLabModels

final class JSONConverter {
    private init() {}

    static func makeWorkModelFrom(json: JSON) -> WorkModel {
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
            children: ChildWorkList(json.children.array.map({
                ChildWorkModel(
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
            })),
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
                        makeWorkGenreFrom(json: $0)
                    })
                )
            }),
            awards: makeAwardListFrom(json: json.awards.win.array + json.awards.nom.array),
            editionBlocks: makeEditionBlocksFrom(json: json.editions_blocks)
        )
    }

    static func makeEditionBlocksFrom(json: JSON) -> [EditionBlockModel] {
        return json.keys.sorted().map { key -> EditionBlockModel in
            makeEditionBlockFrom(json: json[key])
        }
    }

    static func makeEditionBlockFrom(json: JSON) -> EditionBlockModel {
        return EditionBlockModel(
            type: json.name.stringValue,
            title: json.title.stringValue,
            list: json.list.array.map({
                EditionPreviewModel(
                    id: $0.edition_id.intValue,
                    langCode: $0.lang_code.stringValue,
                    year: $0.year.intValue,
                    coverURL: URL.from(string: "/images/editions/big/\($0.edition_id.intValue)", defaultHost: Hosts.data),
                    correctLevel: $0.correct_level.floatValue
                )
            }).sorted(by: { (x, y) -> Bool in
                x.year > y.year
            })
        )
    }

    static func makeWorkGenreFrom(json: JSON) -> WorkModel.GenreGroupModel.GenreModel {
        return WorkModel.GenreGroupModel.GenreModel(
            id: json.genre_id.intValue,
            label: json.label.stringValue,
            votes: json.votes.intValue,
            percent: json.percent.floatValue,
            genres: json.genre.array.map({
                makeWorkGenreFrom(json: $0)
            })
        )
    }

    static func makeAwardListFrom(json: [JSON]) -> [AwardPreviewModel] {
        let jsonTable = Dictionary(grouping: json) { $0.award_id.stringValue }

        let awards = jsonTable.map { (_, group) in
            AwardPreviewModel(
                id: group[0].award_id.intValue,
                name: group[0].award_name.stringValue,
                rusName: group[0].award_rusname.stringValue,
                isOpen: group[0].award_is_opened.boolValue,
                iconURL: URL.from(string: group[0].award_icon.stringValue),
                contests: group.map({
                    AwardPreviewModel.ContestModel(
                        id: $0.contest_id.intValue,
                        year: $0.contest_year.intValue,
                        name: $0.nomination_rusname.string ?? $0.nomination_name.stringValue,
                        workId: $0.work_id.intValue,
                        workName: $0.work_rusname.string ?? $0.work_name.stringValue,
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

    static func makeWorkReviewsFrom(json: JSON) -> [WorkReviewModel] {
        return json.items.array.map {
            WorkReviewModel(
                id: $0.response_id.intValue,
                date: Date.from(string: $0.response_date.stringValue, format: "yyyy-MM-dd HH:mm:ss"),
                text: $0.response_text.stringValue,
                votes: $0.response_votes.intValue,
                mark: $0.mark.intValue,
                user: WorkReviewModel.UserModel(
                    id: $0.user_id.intValue,
                    name: $0.user_name.stringValue,
                    avatar: URL.from(string: $0.user_avatar.stringValue)
                )
            )
        }
    }

    static func makeWorkPreviewsFrom(json: JSON) -> [WorkPreviewModel] {
        return json.array.map {
            return WorkPreviewModel(
                id: $0.id.intValue,
                name: $0.name.stringValue,
                nameOrig: $0.name_orig.stringValue,
                workType: $0.name_type.stringValue,
                imageURL: URL.from(string: $0.image.stringValue),
                year: $0.year.intValue,
                authors: $0.creators.authors.array.map({
                    $0.name.string ?? $0.name_orig.stringValue
                }),
                rating: $0.stat.rating.floatValue,
                votes: $0.stat.voters.intValue,
                reviewsCount: $0.stat.responses.intValue
            )
        }
    }

    static func makeAuthorModelFrom(json: JSON) -> AuthorModel {
        return AuthorModel(
            id: json.id.intValue,
            isOpened: json.is_opened.boolValue,
            name: json.name.stringValue,
            origName: json.name_orig.stringValue,
            pseudonyms: json.name_pseudonyms.array.map({ $0.name.string ?? $0.name_orig.stringValue }).filter({ !($0.isEmpty) }),
            countryName: json.country_name.stringValue,
            countryCode: json.country_id.stringValue,
            imageURL: URL.from(string: json.image.stringValue),
            birthDate: Date.from(string: json.birthday.stringValue, format: "yyyy-MM-dd"),
            deathDate: Date.from(string: json.deathday.stringValue, format: "yyyy-MM-dd"),
            bio: json.biography.stringValue,
            notes: json.biography_notes.stringValue,
            compiler: json.compiler.stringValue,
            sites: json.sites.array.map({
                AuthorModel.SiteModel(
                    link: $0.site.stringValue,
                    title: $0.descr.stringValue
                )
            }),
            awards: makeAwardListFrom(json: json.awards.win.array + json.awards.nom.array),
            workBlocks: ChildWorkList((json.cycles_blocks.keys.map({ json.cycles_blocks[$0] }) + json.works_blocks.keys.map({ json.works_blocks[$0] })).flatMap(makeWorksBlockFrom))
        )
    }

    static func makeWorksBlockFrom(json: JSON) -> [ChildWorkModel] {
        var items: [ChildWorkModel] = [
            ChildWorkModel(
                id: 0,
                name: json.title.stringValue,
                origName: "",
                nameBonus: "",
                rating: 0,
                votes: 0,
                workType: "",
                workTypeKey: "",
                publishStatus: "",
                isPublished: true,
                year: 0,
                deepLevel: 1,
                plus: false
            )
        ]

        makeAuthorChildWorksFrom(json: json.list, storage: &items)

        return items
    }

    private static func makeAuthorChildWorksFrom(json: JSON, storage: inout [ChildWorkModel]) {
        json.array.forEach {
            let model = ChildWorkModel(
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
                deepLevel: $0.deep.intValue + 2,
                plus: $0.plus.boolValue
            )

            storage.append(model)

            makeAuthorChildWorksFrom(json: $0.children, storage: &storage)
        }
    }

    static func makeEditionFrom(json: JSON) -> EditionModel {
        var isbn = json.isbns[0].stringValue

        // 978-2-2-07-25804-0 [<small>2-207-25804-1</small>]
        isbn = isbn.split(separator: " ").first.flatMap({ String($0) }) ?? isbn

        var format = json.format.stringValue
        format = format == "0" ? "" : format

        let publisher = json.creators.publishers.array.map({ $0.name.stringValue }).compactAndJoin(" ")

        return EditionModel(
            id: json.edition_id.intValue,
            name: json.edition_name.stringValue,
            image: URL.from(string: json.image.stringValue),
            correctLevel: json.correct_level.floatValue,
            year: json.year.intValue,
            planDate: json.plan_date.stringValue,
            type: json.edition_type.stringValue,
            copies: json.copies.intValue,
            pages: json.pages.intValue,
            coverType: json.cover_type.stringValue,
            publisher: publisher,
            format: format,
            isbn: isbn,
            lang: json.lang.stringValue,
            content: json.content.array.map({ $0.stringValue }),
            description: json["description"].stringValue,
            notes: json.notes.stringValue,
            planDescription: json.plan_description.stringValue
        )
    }
}