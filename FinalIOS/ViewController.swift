//
//  ViewController.swift
//  BasicUI
//
//  Created by Akira Watanabe on 12/2/20.
//

import UIKit

struct Response: Codable{
    var originalWord: String
    var translation: String
}
class ViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var wordList: UITableView!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var showButton: UIButton!
    @IBOutlet weak var wordInput: UITextField!
    
    var words = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        wordList.delegate = self
        wordList.dataSource = self
        wordInput.delegate = self

    }
    
    @IBAction func addWord(_ sender: Any) {
        if wordInput.text != "" {
            words.append(wordInput.text!)
            self.wordList.reloadData()
            wordInput.text = ""
        }

        wordInput.resignFirstResponder()
    }
    @IBAction func showAllWords(_ sender: Any) {
        let group = DispatchGroup()
        var localWords = [String]()
        for element in self.words {
            let val = UserDefaults.standard.object(forKey:element) as? String
            print(element)
            if val == nil {
                group.enter()
                getTranslation(element) { (success, error, translation) in
                    print("Succ en")
                    group.leave()
                    if !success {
                        DispatchQueue.main.async {
                            self.words.remove(at: self.words.firstIndex(of: element)!)
                            self.wordList.reloadData()
                        }
                        return
                    }
                    print("Succ")
                    UserDefaults.standard.set(translation, forKey: element)
                    localWords.append(translation!)
                }
                
            }else{
                localWords.append(val!)
            }
        }
        print("words")
        print(localWords)
        group.notify(queue: .main) {
            self.showAlert("Words translation", localWords.joined(separator: " "))
        }
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "wordCell", for: indexPath)
        cell.textLabel?.text = words[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return words.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selectedWord = words[indexPath.row]
        let translation = UserDefaults.standard.object(forKey:selectedWord) as? String
        if (translation != nil) {
            print("Translation From UserDefaults")
            DispatchQueue.main.async {
                self.showAlert("Word translation", translation!)
            }
        }
        else{
            print(type(of: selectedWord))
            getTranslation(selectedWord) { (success, error, translation) in
                if !success{
                    DispatchQueue.main.async {
                        self.words.remove(at: indexPath.row)
                        self.wordList.deleteRows(at: [indexPath], with: .automatic)
                    }
                    return
                }
            
                UserDefaults.standard.set(translation, forKey: selectedWord)
                DispatchQueue.main.async {
                    self.showAlert("Word translation", translation!)
                }
                return
                
            }
                
        }
    }
}


extension ViewController {
    
    func showAlert(_ title: String, _ text: String){
        let alert = UIAlertController(title: title, message: text, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default))
        self.present(alert, animated: true, completion: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if wordInput.text != "" {
            words.append(wordInput.text!)
            self.wordList.reloadData()
            wordInput.text = ""
        }
        wordInput.resignFirstResponder()
        return true
    }
    
    func getTranslation(_ word: String!, completion:@escaping (_ success:Bool,_ error:Error?, _ _data: String?)->Void) -> () {
        if let url = URL(string: "https://aucatranslator.azurewebsites.net/api/v1/wordtranslation/?word=\(word!)") {

            let task = URLSession.shared.dataTask(with: url, completionHandler: { data, response, error in
                let status = (response as! HTTPURLResponse).statusCode
                if error != nil || status == 404  {
                    return completion(false, nil, nil)
                }
                
                if let data = data {
                    if let decodedResponse = try? JSONDecoder().decode(Response.self, from: data) {
                        return completion(true, nil, decodedResponse.translation)
                    }
                }
                
            })
            task.resume()
        } else{
            return
        }
    }
}
