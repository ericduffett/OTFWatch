//
//  InterfaceController.swift
//  OTFWatch WatchKit Extension
//
//  Created by Duffett, Eric on 7/26/18.
//  Copyright © 2018 Undaunted Athlete, LLC. All rights reserved.
//

import WatchKit
import Foundation
import HealthKit


class InterfaceController: WKInterfaceController, HKWorkoutSessionDelegate {

    
    @IBOutlet var splatImage: WKInterfaceImage!
    @IBOutlet var splatLabel: WKInterfaceLabel!
    
    @IBOutlet var zoneGroup: WKInterfaceGroup!
    @IBOutlet var percentageLabel: WKInterfaceLabel!
    
    @IBOutlet var bpmImage: WKInterfaceImage!
    @IBOutlet var bpmLabel: WKInterfaceLabel!
    
    @IBOutlet var calsImage: WKInterfaceImage!
    @IBOutlet var calsLabel: WKInterfaceLabel!
    
    var splatPoints = 0
    var heartRate: HKQuantity?
    var caloriesBurned: HKQuantity?
    var percentOfMax: Int?
    var maxHeartRate = 225
    var bodyWeight: HKQuantity?
    var age: Int!

    let zones = [#colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1), #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1), #colorLiteral(red: 0.1594775307, green: 0.6253767449, blue: 0.1591489511, alpha: 1), #colorLiteral(red: 1, green: 0.5781051517, blue: 0, alpha: 1), #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1)]
    
    let healthStore = HKHealthStore()
    var workout: HKWorkout?
    var observerQuery: HKObserverQuery?
    var heartRateUnit: HKUnit?
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        if age == nil {
            age = 33
        }
        
        maxHeartRate -= age
        print("max heart rate: \(maxHeartRate)")
        
      //  updatePercentageLabel(HeartRate: 88, maxHR: maxHeartRate)
     
        let allTypes = Set([HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
                            HKObjectType.quantityType(forIdentifier: .heartRate)!,
                            HKObjectType.quantityType(forIdentifier: .bodyMass)!])
        
        healthStore.requestAuthorization(toShare: allTypes, read: allTypes) { (success, error) in
            if !success {
                // Handle the error here.
                print("Did not get access to health store")
            } else {
                //Can read all types
             print("Got access to health store")
                //self.listenForHeartBeat()
                self.observerHeartRateSamples()

            }
        }
        
        workout = context as? HKWorkout
        startWorkout()
        // Configure interface objects here.
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
       
        
     //   bpmLabel.setText("")
      //  calsLabel.setText("\(String(describing: workout.totalEnergyBurned))")
        
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func startWorkout() {
        
      //  guard let workout = workout else {return}
        let config = HKWorkoutConfiguration()
        config.activityType = .crossTraining
        config.locationType = .indoor
        
        do {
            let session = try HKWorkoutSession(configuration: config)
            session.delegate = self
            healthStore.start(session)
        } catch let error as NSError {
            fatalError("Unable to create workout session \(error.localizedDescription)")
        }
        
    }
    
    func observerHeartRateSamples() {
        let heartRateSampleType = HKObjectType.quantityType(forIdentifier: .heartRate)
        
        if let observerQuery = observerQuery {
            healthStore.stop(observerQuery)
        }
        
        observerQuery = HKObserverQuery(sampleType: heartRateSampleType!, predicate: nil) { (_, _, error) in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            
            self.fetchLatestHeartRateSample { (sample) in
                guard let sample = sample else {
                    return
                }
                
                DispatchQueue.main.async {
                    let heartRate = sample.quantity.doubleValue(for: self.heartRateUnit!)
                    print("Heart Rate Sample: \(heartRate)")
                 //   self.updateHeartRate(heartRateValue: heartRate)
                    self.updateHeartRateZone(currentHR: Int(heartRate), maxHR: self.maxHeartRate)
                }
            }
        }
        
        healthStore.execute(observerQuery!)
    }
    
    func fetchLatestHeartRateSample(completionHandler: @escaping (_ sample: HKQuantitySample?) -> Void) {
        guard let sampleType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate) else {
            completionHandler(nil)
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: sampleType,
                                  predicate: predicate,
                                  limit: Int(HKObjectQueryNoLimit),
                                  sortDescriptors: [sortDescriptor]) { (_, results, error) in
                                    if let error = error {
                                        print("Error: \(error.localizedDescription)")
                                        return
                                    }
                                    
                                    completionHandler(results?[0] as? HKQuantitySample)
        }
        
        healthStore.execute(query)
    }
    
    func listenForHeartBeat() {
      guard  let sampleType =
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate) else {return}
        let query = HKObserverQuery(sampleType: sampleType, predicate: nil) { (query, completionHandler, error) in
            
            if error != nil {
                //There was an error
                //abort()
                print("error listening for heartbeat")
            }
        }
        
        healthStore.execute(query)
        
        
        /// When the completion is called, an other query is executed
        /// to fetch the latest heart rate
        self.getLatestHeartBeat(completion: { sample in
            guard let sample = sample else {
                return
            }
            
            /// The completion in called on a background thread, but we
            /// need to update the UI on the main.
            DispatchQueue.main.async {
                
                /// Converting the heart rate to bpm
                let heartRateUnit = HKUnit(from: "count/min")
                let heartRate = sample
                    .quantity
                    .doubleValue(for: heartRateUnit)
                
                /// Updating the UI with the retrieved value
                self.bpmLabel.setText("\(Int(heartRate))")
                self.updatePercentageLabel(HeartRate: Int(heartRate), maxHR: self.maxHeartRate)
               // self.updatePercentageLabel(HeartRate: Int(heartRate))
            }
        })
    
    }
    
 
  
    func getLatestHeartBeat(completion: @escaping (_ sample: HKQuantitySample?) -> Void) {
        
        // Create sample type for the heart rate
        guard let sampleType = HKObjectType
            .quantityType(forIdentifier: .heartRate) else {
                completion(nil)
                return
        }
        
        /// Predicate for specifiying start and end dates for the query
        let predicate = HKQuery
            .predicateForSamples(
                withStart: Date.distantPast,
                end: Date(),
                options: .strictEndDate)
        
        /// Set sorting by date.
        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: false)
        
        /// Create the query
        let query = HKSampleQuery(
            sampleType: sampleType,
            predicate: predicate,
            limit: Int(HKObjectQueryNoLimit),
            sortDescriptors: [sortDescriptor]) { (_, results, error) in
                
                guard error == nil else {
                    print("Error: \(error!.localizedDescription)")
                    return
                }
                
                completion(results?[0] as? HKQuantitySample)
        }
        
        self.healthStore.execute(query)
        
    }
    
    func updatePercentageLabel(HeartRate: Int, maxHR: Int) {
        let percentageString:Int = Int((Double(HeartRate)/Double(maxHR))*100)
        print(percentageString)
        let percentage: String = "\(percentageString)%"
        let cstmFont = UIFont(name: "Raleway-SemiBold", size: 55)!
        let attrStr = NSAttributedString(string: percentage, attributes: [kCTFontAttributeName as NSAttributedStringKey : cstmFont])
        percentageLabel.setAttributedText(attrStr)
        updateHeartRateZone(currentHR: HeartRate, maxHR: maxHR)
    }
    
    func updateHeartRateZone(currentHR: Int, maxHR: Int) {
        print(currentHR)
        let percent:Double = (Double(currentHR)/Double(maxHR)) * 100
        print(percent)
        var zone = 0
        switch percent {
        case 0...60:
            zone = 0
        case 61...70:
            zone = 1
        case 71...83:
            zone = 2
        case 84...91:
            zone = 3
        case 92...150:
            zone = 4
        default:
            zone = 0
        }
        
       let hrColor = zones[zone]
        
        zoneGroup.setBackgroundColor(hrColor)
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        print("to State: \(toState)")
        print("from state: \(fromState)")
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("failed workout")
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didGenerate event: HKWorkoutEvent) {
        print("created event")
    }
    
    
}
