public enum ReviewsSort: String, CaseIterable, CustomStringConvertible {
    case date
    case rating
    case mark

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
