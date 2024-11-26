class Network {

    static func request(urlString: String, 
                        requiresCaching: Bool = true,
                        success: @escaping (String)->(),
                        failure: @escaping ()->() = {}) {
        
        if let cache = CacheHelper.shared.value(key: urlString) {
            if let result = String(data: cache, encoding: .utf8) {
                success(result)
            }
            return
        }
        
        guard let url = URL(string: urlString) else {
            fatalError("URL is nil")
        }
        
        let request = URLRequest(url: url)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    failure()
                    print("system error = \(error.localizedDescription)")
                } else {
                    if let data = data {
                        if requiresCaching {
                            CacheHelper.shared.insert(key: urlString, data: data)
                        }
                        if let result = String(data: data, encoding: .utf8) {
                            success(result)
                        }
                    }
                }
            }
        }
        task.resume()
    }
}


class CacheHelper {
    static let shared = CacheHelper()
    
    static let expiredSeconds: Double = 60
    
    static let defaultKey = "default_key"
    
    var cacheContainer: [String: Any] {
        get {
            UserDefaults.standard.dictionary(forKey: CacheHelper.defaultKey) ?? [:]
        }
        
        set {
            UserDefaults.standard.setValue(newValue, forKey: CacheHelper.defaultKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    func insert(key: String, data: Data) {
        if value(key: key) != nil {
            return
        }
        
        var dict = cacheContainer
        dict[key] =  [
            "date": Date(),
            "value": data
        ]
        cacheContainer = dict
    }
    
    func value(key: String) -> Data? {
        
        var dict = cacheContainer
        guard let resultDict = dict[key] as? [String: Any] else {
            return nil
        }
        guard let date = resultDict["date"] as? Date else {
            return nil
        }
        let timeInterval = Date().timeIntervalSince(date)
        if timeInterval >= CacheHelper.expiredSeconds {
            dict.removeValue(forKey: key)
            cacheContainer = dict
            return nil
        }
        return resultDict["value"] as? Data
    }
}
