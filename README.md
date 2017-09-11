# GsonSwift
A Swift serialization/deserialization library that can convert Swift Objects into JSON and back. This work is inspired by [Gson](https://github.com/google/gson), an awesome Java library which built by Google. 

## Requirements

- Xcode 8.0+
- Swift 3.0+

## Install
```
pod 'GsonSwift', :git => 'https://github.com/speshiou/GsonSwift.git'
```

## Usage

```swift
// Convert JSON string to object
Gson().fromJson(jsonString: json_string, to: TheClassExtendsNSObject.self)
// Convert object to JSON string
Gson().toJsonString(obj)
```
