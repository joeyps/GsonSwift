//
//  Gson.swift
//  Jourmap
//
//  Created by Joey.Ps Huang on 2016/9/16.
//  Copyright © 2016年 Jourmap. All rights reserved.
//

import UIKit

class Gson {
    init() {
        
    }
    
    func fromJson<T: NSObject>(jsonString: String, to type: T.Type) -> T {
        if let data = jsonString.data(using: .utf8) {
            return self.fromJson(jsonData: data, to: type)
        } else {
            return type.init()
        }
    }
    
    func fromJson<T: NSObject>(jsonData: Data, to type: T.Type) -> T {
        let obj = type.init()
        
        do {
            let jsonObj = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions(rawValue: 0))
            
            if let dict = jsonObj as? Dictionary<String, Any> {
                self.applyValuesOf(obj: obj, dict: dict)
                return obj
            }
        } catch {
            NSLog(error.localizedDescription)
            return obj
        }
        
        return obj
    }
    
    func fromJson<T: NSObject>(dict: [String: Any], to type: T.Type) -> T {
        let obj = type.init()
        self.applyValuesOf(obj: obj, dict: dict)
        return obj
    }
    
    /**
     Converts the class to JSON.
     - returns: The class as JSON, wrapped in NSData.
     */
    func toJson(_ obj: NSObject, prettyPrinted : Bool = false) -> Data? {
        let dictionary = self.toDictionary(from: obj)
        do {
            let json = try JSONSerialization.data(withJSONObject: dictionary, options: (prettyPrinted ? .prettyPrinted : JSONSerialization.WritingOptions()))
            return json
        } catch let error as NSError {
            print("ERROR: Unable to serialize json, error: \(error)")
            NotificationCenter.default.post(name: Notification.Name(rawValue: "CrashlyticsLogNotification"), object: self, userInfo: ["string": "unable to serialize json, error: \(error)"])
        }
        
        return nil
    }
    
    /**
     Converts the class to a JSON string.
     - returns: The class as a JSON string.
     */
    func toJsonString(_ obj: NSObject, prettyPrinted : Bool = false) -> String? {
        if let jsonData = self.toJson(obj, prettyPrinted: prettyPrinted) {
            return String(data: jsonData, encoding: .utf8)
        }
        
        return nil
    }
    
    internal func toDictionary(from obj: NSObject) -> [String: Any] {
        var propertiesDictionary = [String: Any]()
        let mirror = Mirror(reflecting: obj)
        
        for (propName, propValue) in mirror.children {
            if let propValue = self.unwrap(propValue), let propName = propName {
                if let arrayPropValue = propValue as? [NSObject] {
                    var subArray = [[String: Any]]()
                    for item in arrayPropValue {
                        subArray.append(self.toDictionary(from: item))
                    }
                    
                    propertiesDictionary[propName] = subArray
                } else if propValue is Int || propValue is Double || propValue is Float {
                    propertiesDictionary[propName] = propValue
                } else if let dataPropValue = propValue as? Data {
                    propertiesDictionary[propName] = dataPropValue.base64EncodedString(options: .lineLength64Characters)
                } else if let boolPropValue = propValue as? Bool {
                    propertiesDictionary[propName] = boolPropValue
                } else if let stringPropValue = propValue as? String {
                    propertiesDictionary[propName] = stringPropValue
                } else if let serializablePropValue = propValue as? NSObject {
                    propertiesDictionary[propName] = self.toDictionary(from: serializablePropValue)
                } else {
                    //                    setValue(propertiesDictionary, value: propValue, forKey: propName)
                }
            }
        }
        
        return propertiesDictionary
    }
    
    internal func unwrap(_ any: Any) -> Any? {
        let mi = Mirror(reflecting: any)
        
        if mi.displayStyle != .optional {
            return any
        }
        
        if mi.children.count == 0 {
            return nil
        }
        
        let (_, some) = mi.children.first!
        
        return some
    }
    
    internal func applyValuesOf(obj: NSObject, dict: Dictionary<String, Any>) {
        let mirror = Mirror(reflecting: obj)
        for (key, value) in dict {
            if key == "description" {
                // skip primitive properties of NSObject
                continue
            }
            if (obj.responds(to: Selector(key))) {
                if value is Int || value is Float || value is Double {
                    guard let child = self.getPropertyOf(mirror: mirror, propName: key) else {
                        continue
                    }
                    if child.value is String || child.value is Optional<String>.Type {
                        obj.setValue(String(describing: value), forKey: key)
                    } else {
                        obj.setValue(value, forKey: key)
                    }
                } else if let value = value as? String {
                    obj.setValue(value, forKey: key)
                } else if value is Bool {
                    obj.setValue(value, forKey: key)
                } else if let ary = value as? Array<Any> {
                    guard ary.count > 0, let child = self.getPropertyOf(mirror: mirror, propName: key) else {
                        continue
                    }
                    
                    if ary is Array<String> || ary is Array<Int> {
                        obj.setValue(ary, forKey: key)
                    } else {
                        let type = type(of: child.value)
                        var classString = String(describing: type)
                        classString = classString.replacingOccurrences(of: "Array<", with: "")
                        classString = classString.replacingOccurrences(of: ">", with: "")
                        
                        let myClass = NSClassFromString("Jourmap.\(classString)") as! NSObject.Type
                        let elements = NSMutableArray()
                        for e in ary {
                            if let dict = e as? Dictionary<String, Any> {
                                let element = myClass.init()
                                self.applyValuesOf(obj: element, dict: dict)
                                elements.add(element)
                            }
                        }
                        obj.setValue(elements, forKey: key)
                    }
                    //  let e = myClass.Element
                } else if let dict = value as? Dictionary<String, Any> {
                    guard let child = self.getPropertyOf(mirror: mirror, propName: key) else {
                        continue
                    }
                    
                    let type = type(of: child.value)
                    var classString = String(describing: type)
                    classString = classString.replacingOccurrences(of: "Optional<", with: "")
                    classString = classString.replacingOccurrences(of: ">", with: "")
                    let myClass = NSClassFromString("Jourmap.\(classString)") as! NSObject.Type
                    let element = myClass.init()
                    self.applyValuesOf(obj: element, dict: dict)
                    obj.setValue(element, forKey: key)
                }
            }
        }
    }
    
    internal func getPropertyOf(mirror: Mirror, propName: String) -> Mirror.Child? {
        let child = mirror.children.first(where: { (child: (label: String?, value: Any)) -> Bool in
            if let label = child.label {
                return label == propName
            }
            return false
        })
        if child != nil {
            return child
        }
        if let mirror = mirror.superclassMirror {
            return self.getPropertyOf(mirror: mirror, propName: propName)
        }
        return nil
    }
    
}
