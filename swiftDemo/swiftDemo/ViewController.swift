//
//  ViewController.swift
//  swiftDemo
//
//  Created by dengbb on 16/9/26.
//  Copyright © 2016年 mohekeji. All rights reserved.
//

import UIKit

class ViewController: UIViewController,UITableViewDataSource {
 
    @IBOutlet var tableView: UITableView!
    
    var meals = [Meal]()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        NSLog("%@demo", "practise");
//        tableView.delegate = self
//        tableView.dataSource = self
        self.loadMealData()
    }

    func loadMealData()  {
        let photo = UIImage(named:"abc")
        let meal1 = Meal(name:"dd" ,photo:photo!)
        
        meals += [meal1]
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
     func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
     func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return meals.count
    }
    
     func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Table view cells are reused and should be dequeued using a cell identifier.
        let cellIdentifier = "MealCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! MealCell
        
        // Fetches the appropriate meal for the data source layout.
        let meal = meals[(indexPath as NSIndexPath).row]
        
        cell.mealLabel.text = meal.name
        cell.mealImageView.image = meal.photo
        
        
        return cell
    }


}

