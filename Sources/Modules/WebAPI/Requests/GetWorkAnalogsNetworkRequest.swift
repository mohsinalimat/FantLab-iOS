import Foundation
import FLKit
import FLModels

public final class GetWorkAnalogsNetworkRequest: NetworkRequest {
    public typealias ModelType = [WorkPreviewModel]

    private let workId: Int

    public init(workId: Int) {
        self.workId = workId
    }

    public func makeURLRequest() -> URLRequest {
        return URLRequest(url: URL(string: "https://\(Hosts.api)/work/\(workId)/similars")!)
    }

    public func parse(response: URLResponse, data: Data) throws -> [WorkPreviewModel] {
        let json = try DynamicJSON(jsonData: data)

        return JSONConverter.makeWorkPreviewsFrom(json: json)
    }
}
