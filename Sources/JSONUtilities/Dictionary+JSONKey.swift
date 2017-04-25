//
//  Dictionary+JSONKey.swift
//  JSONUtilities
//
//  Created by Luciano Marisi on 05/03/2016.
//  Copyright © 2016 Luciano Marisi All rights reserved.
//

import Foundation

/// Protocol used for defining the valid JSON types, i.e. Int, Double, Float, String and Bool
public protocol JSONRawType {}
extension Int : JSONRawType {}
extension Double : JSONRawType {}
extension Float : JSONRawType {}
extension String : JSONRawType {}
extension Bool : JSONRawType {}

/// The behaviour of what should be done when an invalid JSON object or primitive is found
///
/// - remove: The item is filtered, only valid items are returned
/// - fail:  The call fails. For non optional properties this will throw an error, and for optional properties nil is returned
public enum InvalidItemBehaviour<T> {
  case remove
  case fail
  case value(T)
  case custom((DecodingError) throws -> T?)
}

// Simple protocol used to extend a JSONDictionary
public protocol StringProtocol {
  func components(separatedBy: String) -> [String]
  var string: String { get }
}
extension String: StringProtocol {
  public var string: String {
    return self
  }
}

extension Dictionary where Key: StringProtocol {

  // MARK: JSONRawType type

  /// Decode a mandatory JSON raw type
  public func json<T: JSONRawType>(atKeyPath keyPath: Key) throws -> T {
    return try getValue(atKeyPath: keyPath)
  }

  /// Decode an optional JSON raw type
  public func json<T: JSONRawType>(atKeyPath keyPath: Key) -> T? {
    return try? json(atKeyPath: keyPath)
  }

  // MARK: [JSONRawType] type

  /// Decode an Array of mandatory JSON raw types
  public func json<T: JSONRawType>(atKeyPath keyPath: Key, invalidItemBehaviour: InvalidItemBehaviour<T> = .remove) throws -> [T] {
    return try decodeArray(atKeyPath: keyPath, invalidItemBehaviour: invalidItemBehaviour, decode: getValue)
  }

  /// Decode an Array of optional JSON raw types
  public func json<T: JSONRawType>(atKeyPath keyPath: Key, invalidItemBehaviour: InvalidItemBehaviour<T> = .remove) -> [T]? {
    return try? self.json(atKeyPath: keyPath, invalidItemBehaviour: invalidItemBehaviour)
  }

  // MARK: [String: Any] type

  /// Decodes as a raw Dictionary with a mandatory key
  public func json(atKeyPath keyPath: Key) throws -> JSONDictionary {
    return try getValue(atKeyPath: keyPath)
  }

  /// Decodes as a raw dictionary with an optional key
  public func json(atKeyPath keyPath: Key) -> JSONDictionary? {
    return self[keyPath: keyPath] as? JSONDictionary
  }

  // MARK: [[String: Any]] type

  /// Decodes as a raw dictionary array with a mandatory key
  public func json(atKeyPath keyPath: Key, invalidItemBehaviour: InvalidItemBehaviour<JSONDictionary> = .remove) throws -> [JSONDictionary] {
    return try decodeArray(atKeyPath: keyPath, invalidItemBehaviour: invalidItemBehaviour, decode: getValue)
  }

  /// Decodes as a raw ictionary array with an optional key
  public func json(atKeyPath keyPath: Key, invalidItemBehaviour: InvalidItemBehaviour<JSONDictionary> = .remove) -> [JSONDictionary]? {
    return try? self.json(atKeyPath: keyPath, invalidItemBehaviour: invalidItemBehaviour)
  }

  // MARK: [String: JSONObjectConvertible] type

  /// Decodes a mandatory dictionary
  public func json<T: JSONObjectConvertible>(atKeyPath keyPath: Key, invalidItemBehaviour: InvalidItemBehaviour<T> = .remove) throws -> [String: T] {
    return try decodeDictionary(atKeyPath: keyPath, invalidItemBehaviour: invalidItemBehaviour) { jsonDictionary, key in
      return try jsonDictionary.json(atKeyPath: key) as T
    }
  }

  /// Decodes an optional dictionary
  public func json<T: JSONObjectConvertible>(atKeyPath keyPath: Key, invalidItemBehaviour: InvalidItemBehaviour<T> = .remove) -> [String: T]? {
    return try? json(atKeyPath: keyPath, invalidItemBehaviour: invalidItemBehaviour) as [String: T]
  }

  // MARK: [String: JSONRawType] type

  /// Decodes a mandatory dictionary
  public func json<T: JSONRawType>(atKeyPath keyPath: Key, invalidItemBehaviour: InvalidItemBehaviour<T> = .remove) throws -> [String: T] {
    return try decodeDictionary(atKeyPath: keyPath, invalidItemBehaviour: invalidItemBehaviour) { jsonDictionary, key in
      return try jsonDictionary.json(atKeyPath: key) as T
    }
  }

  /// Decodes an optional dictionary
  public func json<T: JSONRawType>(atKeyPath keyPath: Key, invalidItemBehaviour: InvalidItemBehaviour<T> = .remove) -> [String: T]? {
    return try? json(atKeyPath: keyPath, invalidItemBehaviour: invalidItemBehaviour) as [String: T]
  }

  // MARK: [String: JSONPrimitiveConvertible] type

  /// Decodes a mandatory dictionary
  public func json<T: JSONPrimitiveConvertible>(atKeyPath keyPath: Key, invalidItemBehaviour: InvalidItemBehaviour<T> = .remove) throws -> [String: T] {
    return try decodeDictionary(atKeyPath: keyPath, invalidItemBehaviour: invalidItemBehaviour) { jsonDictionary, key in
      return try jsonDictionary.json(atKeyPath: key) as T
    }
  }

  /// Decodes an optional dictionary
  public func json<T: JSONPrimitiveConvertible>(atKeyPath keyPath: Key, invalidItemBehaviour: InvalidItemBehaviour<T> = .remove) -> [String: T]? {
    return try? json(atKeyPath: keyPath, invalidItemBehaviour: invalidItemBehaviour) as [String: T]
  }

  // MARK: Decodable types

  /// Decode a mandatory Decodable object
  public func json<T: JSONObjectConvertible>(atKeyPath keyPath: Key) throws -> T {
    return try T(jsonDictionary: JSONDictionaryForKey(atKeyPath: keyPath))
  }

  /// Decode an optional Decodable object
  public func json<T: JSONObjectConvertible>(atKeyPath keyPath: Key) -> T? {
    return try? T(jsonDictionary: JSONDictionaryForKey(atKeyPath: keyPath))
  }

  // MARK: [Decodable] types

  /// Decode an Array of mandatory Decodable objects
  public func json<T: JSONObjectConvertible>(atKeyPath keyPath: Key, invalidItemBehaviour: InvalidItemBehaviour<T> = .remove) throws -> [T] {
    return try decodeArray(atKeyPath: keyPath, invalidItemBehaviour: invalidItemBehaviour) { keyPath, jsonArray, value in
      let jsonDictionary: JSONDictionary = try getValue(atKeyPath: keyPath, array: jsonArray, value: value)
      return try T(jsonDictionary: jsonDictionary)
    }
  }

  /// Decode an Array of optional Decodable objects
  public func json<T: JSONObjectConvertible>(atKeyPath keyPath: Key, invalidItemBehaviour: InvalidItemBehaviour<T> = .remove) -> [T]? {
    return try? json(atKeyPath: keyPath, invalidItemBehaviour: invalidItemBehaviour)
  }

  // MARK: RawRepresentable type

  /// Decode a mandatory RawRepresentable
  public func json<T: RawRepresentable>(atKeyPath keyPath: Key) throws -> T where T.RawValue:JSONRawType {
    let rawValue: T.RawValue = try getValue(atKeyPath: keyPath)

    guard let value = T(rawValue:rawValue) else {
      throw DecodingError(dictionary: self, keyPath: keyPath, expectedType: T.self, value: rawValue, reason: .incorrectRawRepresentableRawValue)
    }

    return value
  }

  /// Decode an optional RawRepresentable
  public func json<T: RawRepresentable>(atKeyPath keyPath: Key) -> T? where T.RawValue:JSONRawType {
    return try? json(atKeyPath: keyPath)
  }

  // MARK: [RawRepresentable] type

  /// Decode an array of custom RawRepresentable types with a mandatory key
  public func json<T: RawRepresentable>(atKeyPath keyPath: Key, invalidItemBehaviour: InvalidItemBehaviour<T> = .remove) throws -> [T] where T.RawValue:JSONRawType {

    return try decodeArray(atKeyPath: keyPath, invalidItemBehaviour: invalidItemBehaviour) { keyPath, jsonArray, value in
      let rawValue: T.RawValue = try getValue(atKeyPath: keyPath, array: jsonArray, value: value)

      guard let value = T(rawValue:rawValue) else {
        throw DecodingError(dictionary: self, keyPath: keyPath, expectedType: T.self, value: rawValue, array: jsonArray, reason: .incorrectRawRepresentableRawValue)
      }
      return value
    }
  }

  /// Optionally decode an array of RawRepresentable types with a mandatory key
  public func json<T: RawRepresentable>(atKeyPath keyPath: Key, invalidItemBehaviour: InvalidItemBehaviour<T> = .remove) -> [T]? where T.RawValue:JSONRawType {
    return try? json(atKeyPath: keyPath, invalidItemBehaviour: invalidItemBehaviour)
  }

  // MARK: JSONPrimitiveConvertible type

  /// Decode a custom raw types with a mandatory key
  public func json<T: JSONPrimitiveConvertible>(atKeyPath keyPath: Key) throws -> T {
    let jsonValue: T.JSONType = try getValue(atKeyPath: keyPath)

    guard let transformedValue = T.from(jsonValue: jsonValue) else {
      throw DecodingError(dictionary: self, keyPath: keyPath, expectedType: T.self, value: jsonValue, reason: .conversionFailure)
    }

    return transformedValue
  }

  /// Optionally decode a custom raw types with a mandatory key
  public func json<T: JSONPrimitiveConvertible>(atKeyPath keyPath: Key) -> T? {
    return try? json(atKeyPath: keyPath)
  }

  // MARK: [JSONPrimitiveConvertible] type

  /// Decode an array of custom raw types with a mandatory key
  public func json<T: JSONPrimitiveConvertible>(atKeyPath keyPath: Key, invalidItemBehaviour: InvalidItemBehaviour<T> = .remove) throws -> [T] {
    return try decodeArray(atKeyPath: keyPath, invalidItemBehaviour: invalidItemBehaviour) { keyPath, jsonArray, value in
      let jsonValue: T.JSONType = try getValue(atKeyPath: keyPath, array: jsonArray, value: value)

      guard let transformedValue = T.from(jsonValue: jsonValue) else {
        throw DecodingError(dictionary: self, keyPath: keyPath, expectedType: T.self, value: jsonValue, array: jsonArray, reason: .conversionFailure)
      }
      return transformedValue
    }
  }

  /// Optionally decode an array custom raw types with a mandatory key
  public func json<T: JSONPrimitiveConvertible>(atKeyPath keyPath: Key, invalidItemBehaviour: InvalidItemBehaviour<T> = .remove) -> [T]? {
    return try? json(atKeyPath: keyPath, invalidItemBehaviour: invalidItemBehaviour)
  }

  // MARK: JSONDictionary and JSONArray creation

  fileprivate func JSONDictionaryForKey(atKeyPath keyPath: Key) throws -> JSONDictionary {
    return try getValue(atKeyPath: keyPath)
  }

  fileprivate func JSONArrayForKey(atKeyPath keyPath: Key) throws -> JSONArray {
    return try getValue(atKeyPath: keyPath)
  }

  // MARK: Value decoding

  fileprivate func getValue<A, B>(atKeyPath keyPath: Key, array: [A], value: A) throws -> B {
    guard let typedValue = value as? B else {
      throw DecodingError(dictionary: self, keyPath: keyPath, expectedType: B.self, value: value, array: array, reason: .incorrectType)
    }
    return typedValue
  }

  fileprivate func getValue<T>(atKeyPath keyPath: Key) throws -> T {
    guard let value = self[keyPath: keyPath] else {
      throw DecodingError(dictionary: self, keyPath: keyPath, expectedType: T.self, value: "", reason: .keyNotFound)
    }
    guard let typedValue = value as? T else {
      throw DecodingError(dictionary: self, keyPath: keyPath, expectedType: T.self, value: value, reason: .incorrectType)
    }
    return typedValue
  }

  // MARK: Dictionary decoding

  fileprivate func decodeDictionary<T>(atKeyPath keyPath: Key, invalidItemBehaviour: InvalidItemBehaviour<T> = .remove, decode: (JSONDictionary, String) throws -> T) throws -> [String: T] {
    let jsonDictionary: JSONDictionary = try json(atKeyPath: keyPath)

    var dictionary: [String: T] = [:]
    for (key, _) in jsonDictionary {

      switch invalidItemBehaviour {
      case .remove:
        if let typedItem = try? decode(jsonDictionary, key) {
          dictionary[key] = typedItem
        }
      case .fail:
        dictionary[key] = try decode(jsonDictionary, key)
      case .value(let value):
        do {
          dictionary[key] = try decode(jsonDictionary, key)
        } catch {
          dictionary[key] = value
        }
      case .custom(let getValue):
        do {
          dictionary[key] = try decode(jsonDictionary, key)
        } catch let error as DecodingError {
          dictionary[key] = try getValue(error)
        }
      }
    }

    return dictionary
  }

  // MARK: Array decoding

  //swiftlint:disable:next large_tuple
  fileprivate func decodeArray<T>(atKeyPath keyPath: Key, invalidItemBehaviour: InvalidItemBehaviour<T> = .remove, decode: (Key, JSONArray, Any) throws -> T) throws -> [T] {
    let jsonArray = try JSONArrayForKey(atKeyPath: keyPath)

    return try jsonArray.flatMap {
      switch invalidItemBehaviour {
      case .remove:
        return try? decode(keyPath, jsonArray, $0)
      case .fail:
        return try decode(keyPath, jsonArray, $0)
      case .value(let value):
        do {
          return try decode(keyPath, jsonArray, $0)
        } catch {
          return value
        }
      case .custom(let getValue):
        do {
          return try decode(keyPath, jsonArray, $0)
        } catch let error as DecodingError {
          return try getValue(error)
        }
      }
    }
  }

}
