# RequestKit

[![Build Status](https://travis-ci.org/nerdishbynature/RequestKit.svg?branch=master)](https://travis-ci.org/nerdishbynature/RequestKit)
[![codecov.io](https://codecov.io/github/nerdishbynature/RequestKit/coverage.svg?branch=master)](https://codecov.io/github/nerdishbynature/RequestKit?branch=master)

The base of [octokit.swift](https://github.com/nerdishbynature/Octokit.swift), [TanukiKit](https://github.com/nerdishbynature/TanukiKit), [TrashCanKit](https://github.com/nerdishbynature/TrashCanKit) and [VloggerKit](https://github.com/nerdishbynature/VloggerKit).

## Installation

### Carthage

```
# Cartfile
github "nerdishbynature/RequestKit"
```

### CocoaPods

```
# Podfile
pod "NBNRequestKit"
```

## Usage

To make a request using RequestKit you will need three parts: a `Router`, a `Configuration` and usually an object that know both and connects them. See [OctoKit](https://github.com/nerdishbynature/octokit.swift/blob/master/OctoKit/Octokit.swift#L3).

### Defining a Router

Router are defined by the `Router` protocol. It is recommended to define them as `Enumerations` having a case for every route.

This is what a basic router looks like:

```swift
enum MyRouter: Router {
    case getMyself(Configuration)

    var configuration: Configuration {
        switch self {
        case .getMyself(let config): return config
        }
    }

    var method: HTTPMethod {
        switch self {
        case .getMyself:
            return .GET
        }
    }

    var encoding: HTTPEncoding {
        switch self {
        case .getMyself:
            return .url
        }
    }

    var path: String {
        switch self {
        case .getMyself:
            return "myself"
        }
    }

    var params: [String: Any] {
        switch self {
        case .getMyself(_):
            return ["key1": "value1", "key2": "value2"]
        }
    }
}
```

## Defining a Configuration

As RequestKit was designed to handle OAuth requests we needed something to store user credentials. This is where Configurations come into play. Configurations are defined in the `Configuration` protocol.

```swift
public struct TokenConfiguration: Configuration {
    public let accessToken: String?
    public let apiEndpoint = "https://my.webservice.example/api/2.0/"
    public let accessTokenFieldName = "access_token"
    public let errorDomain = "com.my.customErrorDomain"
    
    public init(_ accessToken: String? = nil) {
        self.accessToken = accessToken
    }
}
```

In the above `Configuration` the `accessToken` will be passed as a URL parameter named `access_token` with each request. Alternatively you can have the `accessToken` passed in an HTTP Authorization header by setting the `authorizationHeader` property to the desired token type. As an example the following `Configuration` passes it as a Bearer token.

```swift
public struct TokenConfiguration: Configuration {
    public let accessToken: String?
    public let apiEndpoint = "https://my.webservice.example/api/2.0/"
    public let authorizationHeader: String? = "Bearer"
    public let errorDomain = "com.my.customErrorDomain"
        
    public init(_ accessToken: String? = nil) {
        self.accessToken = accessToken
    }
}
```

## Defining the binding object

We will need something that connects the router and the configuration to make provide a convenient interface. The common way of doing this is to use a `struct` or a `class` that does it for you.

```swift
struct User : Codable {
}

struct MyWebservice {
    var configuration: Configuration

    init(configuration: Configuration) {
        self.configuration = configuration
    }

    func getMyself(session: RequestKitURLSession = URLSession.shared, completion: @escaping (_ response: Response<User>) -> Void) -> URLSessionDataTaskProtocol? {
        let router = MyRouter.getMyself(self.configuration)
        return router.load(session, expectedResultType: User.self) { user, error in
            if let error = error {
                completion(Response.failure(error))
            } else if let user = user {
                completion(Response.success(user))
            }
        }
    }
}
```

## Making a request

All your user has to do is call your `MyWebservice`:

```swift
let config = TokenConfiguration("123456")
MyWebservice(configuration:config).getMyself { response in
    switch response {
        case .success(let user):
            print(user)
        case .failure(let error):
            print(error)
        }
    }
}
```
