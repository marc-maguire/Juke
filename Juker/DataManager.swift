//
//  DataManager.swift
//  FoodTracker
//
//  Created by Marc Maguire on 2017-06-05.
//  Copyright © 2017 Apple Inc. All rights reserved.
//

import UIKit
import Alamofire


class DataManager {
    
    private static var sharedInstance: DataManager = {
        let dataManager = DataManager()
        //do any additional configuration
        
        return dataManager
    }()
    
    //MARK: - Init
    
    private init() {
        
    }
    //MARK: Accessor Method
    
    class func shared() -> DataManager {
        return sharedInstance
    }
    
    //MARK: - Network Calls
    
    //get random image
    
    
    
    
    static func fetchImage(completion:@escaping(UIImage?)->()) {
        let session = URLSession.shared
        
        let components = URLComponents(string: "http://lorempixel.com/200/300")!
        
        let request = URLRequest(url: components.url!)
        session.dataTask(with: request) { (data: Data?, response:URLResponse?, error: Error?) in
            
            var image: UIImage?
            
            defer {
                completion(image)
            }
            
            if let error = error {
                print(#line, error.localizedDescription)
                return
            }
            
            guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                print(#line, "response is nil or status code not 200")
                return
            }
            
            guard let data = data else {
                print(#line, "no data")
                return
            }
            print(#line, data)
            image = UIImage(data: data)
            print(#line, image!)
            
            //            completion(image)
            }.resume()
        
    }
    
    static func fetchQuote(completion:@escaping(String?)->()) {
        
        let session = URLSession.shared
        let components = URLComponents(string: "http://api.forismatic.com/api/1.0/?method=getQuote&lang=en&format=json")!
        let request = URLRequest(url: components.url!)
        
        
        
        session.dataTask(with: request) { (data: Data?, response:URLResponse?, error: Error?) in
            
            var quote: String?
            //when we call this and the above, we need to create our data model object and store it in an array
            
            
            defer {
                completion(quote)
            }
            
            if let error = error {
                print(#line, error.localizedDescription)
                return
            }
            
            guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                print(#line, "response is nil or status code not 200")
                return
            }
            
            
            guard let data = data else {
                print(#line, "no data")
                return
            }
            
            do {
                var json = try JSONSerialization.jsonObject(with: data, options: []) as! [String:String]
                if let json = json["quoteText"] {
                    quote = json
                    completion(quote)
                }
                
            } catch {
                print(#line, "could not get json")
            }
            
            }.resume()
        
    }

/*   private func fetchQuote() {
 NetworkManager.fetchQuote { [weak self] (quoteString: String?) in
 guard let quoteString = quoteString else {
 print(#line, "no quote")
 return
 }
 guard let welf = self else {
 return
 }
 welf.quoteLabel.text = quoteString
 }
 }
*/
 
    

 
    }


/*
 + (NSURL *)createURLFromSearchString:(NSString *)string {
 NSURLComponents *URLFromComponents = [[NSURLComponents alloc]init];
 
 URLFromComponents.scheme = @"https";
 URLFromComponents.host = @"api.flickr.com";
 URLFromComponents.path = @"/services/rest/";
 
 NSURLQueryItem *method = [[NSURLQueryItem alloc]initWithName:@"method" value:@"flickr.photos.search"];
 NSURLQueryItem *APIKey = [[NSURLQueryItem alloc]initWithName:@"api_key" value:API_KEY];
 NSURLQueryItem *tags = [[NSURLQueryItem alloc]initWithName:@"tags" value:string];
 NSURLQueryItem *hasGeo = [[NSURLQueryItem alloc]initWithName:@"has_geo" value:@"1"];
 NSURLQueryItem *format = [[NSURLQueryItem alloc]initWithName:@"format" value:@"json"];
 NSURLQueryItem *extras = [[NSURLQueryItem alloc]initWithName:@"extras" value:@"url_m"];
 NSURLQueryItem *noJson = [[NSURLQueryItem alloc]initWithName:@"nojsoncallback" value:@"1"];
 URLFromComponents.queryItems = @[method, APIKey, tags, hasGeo, extras, format, noJson];
 
 NSLog(@"%@",URLFromComponents.URL);
 return URLFromComponents.URL;
 }
 */
 
