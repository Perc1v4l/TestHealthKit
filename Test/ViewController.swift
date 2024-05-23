//
//  ViewController.swift
//  Test
//
//  Created by Alex Volodin on 23.05.2024.
//

import UIKit
import HealthKit

class ViewController: UIViewController {
    
    let healthKitStore = HKHealthStore()
    
    func readProfile() -> (age:DateComponents?, bioSex:HKBiologicalSexObject?)
    {
        var dateOfBirth : DateComponents?
        var bioSex : HKBiologicalSexObject?
        
        do {
            dateOfBirth = try healthKitStore.dateOfBirthComponents()
            bioSex = try healthKitStore.biologicalSex()
        }
        catch{
            print(error)
        }
        return (dateOfBirth, bioSex)
    }
    
    func authorizeHealthKit(completion: ((_ success:Bool, _ error:NSError?) -> Void)!)
    {
        let healthKitTypesToRead = Set(arrayLiteral:
                                        HKObjectType.characteristicType(forIdentifier: HKCharacteristicTypeIdentifier.dateOfBirth)!,
                                       HKObjectType.characteristicType(forIdentifier: HKCharacteristicTypeIdentifier.biologicalSex)!,
                                       HKObjectType.quantityType(forIdentifier:HKQuantityTypeIdentifier.bodyMass)!,
                                       HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!)
        
        let healthKitTypesToWrite = Set(arrayLiteral:
                                            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned)!,
                                        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceWalkingRunning)!,
                                        HKObjectType.quantityType(forIdentifier:
                                            HKQuantityTypeIdentifier.bodyMass)!,
                                        HKObjectType.quantityType(forIdentifier:
                                            HKQuantityTypeIdentifier.bodyMassIndex)!)
        
        if !HKHealthStore.isHealthDataAvailable()
        {
            fatalError("*** An unexpected error occurred while requesting authorization: ***")
        }
        healthKitStore.requestAuthorization(toShare: healthKitTypesToWrite, read: healthKitTypesToRead) {
            (success, error) -> Void in
            if( completion != nil )
            {
                completion(success,error as NSError?)
            }
        }
        let profile = readProfile()
                print(profile)
    }
    
    func readMostRecentSample(sampleType:HKSampleType , completion: ((HKSample?, NSError?) -> Void)!)
        {
            
            // 1. Build the Predicate
            let past = NSDate.distantPast
            let now   = NSDate()
            let mostRecentPredicate = HKQuery.predicateForSamples(withStart: past, end:now as Date)
            
            // 2. Build the sort descriptor to return the samples in descending order
            let sortDescriptor = NSSortDescriptor(key:HKSampleSortIdentifierStartDate, ascending: false)
            // 3. we want to limit the number of samples returned by the query to just 1 (the most recent)
            let limit = 3
            
            // 4. Build samples query
            let sampleQuery = HKSampleQuery(sampleType: sampleType, predicate: mostRecentPredicate, limit: limit, sortDescriptors: [sortDescriptor])
                { (sampleQuery, results, error ) -> Void in
                    
                    if let queryError = error {
                        completion(nil,error as NSError?)
                        return;
                    }
                    print(results!.count)
                    // Get the first sample
                    let mostRecentSample = results!.first as? HKQuantitySample
                    
                    // Execute the completion closure
                    if completion != nil {
                        completion(mostRecentSample,nil)
                    }
            }
            // 5. Execute the Query
            self.healthKitStore.execute(sampleQuery)
        }

//        func saveBMISample(bmi:Double, date:NSDate ) {
//
//            // 1. Create a BMI Sample
//            let bmiType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMassIndex)
//            let bmiQuantity = HKQuantity(unit: HKUnit.count(), doubleValue: bmi)
//            let bmiSample = HKQuantitySample(type: bmiType!, quantity: bmiQuantity, start: date as Date, end: date as Date)
//
//            // 2. Save the sample in the store
//            healthKitStore.save(bmiSample, withCompletion: { (success, error) -> Void in
//                if( error != nil ) {
//                    print("Error saving BMI sample: \(error!.localizedDescription)")
//                } else {
//                    print("BMI sample saved successfully!")
//                }
//            })
//        }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
                authorizeHealthKit { (authorized,  error) -> Void in
                    if authorized {
                        print("HealthKit authorization received.")
                        let profile = self.readProfile()
                        print(profile)
                        
                        var kilograms: Double = 0.0

                        // 1. Construct an HKSampleType for weight
                        let sampleType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass)
                        
                        // 2. Call the method to read the most recent weight sample
                        self.readMostRecentSample(sampleType: sampleType!, completion: { (mostRecentWeight, error) -> Void in
                            
                            if( error != nil )
                            {
                                print("Error reading weight from HealthKit Store: \(String(describing: error?.localizedDescription))")
                                return;
                            }
                            var weight: HKQuantitySample
                            var weightLocalizedString = "empty"
                            // 3. Format the weight to display it on the screen
                            weight = (mostRecentWeight as? HKQuantitySample)!;
                            kilograms = weight.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
                            let weightFormatter = MassFormatter()
                            weightFormatter.isForPersonMassUse = true;
                            weightLocalizedString = weightFormatter.string(fromKilograms: kilograms)
                            
                            // 4. Print the result
                            print(weightLocalizedString)

                            let weightInKilograms = kilograms
                            let heightInMeters: Double = 1.80
                            print(weightInKilograms)
                            print(heightInMeters)
                            let bmi  = weightInKilograms / (heightInMeters * heightInMeters)
                            
                            // 3. Show the calculated BMI
                            print(String(format: "%.02f", bmi))
                            
                            // Store bmi
                            //self.saveBMISample(bmi: bmi, date: NSDate())

                            });

                    }
                    else
                    {
                        print("HealthKit authorization denied!")
                        if error != nil {
                            print("\(String(describing: error))")
                        }
                    }
                }
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
            super.didReceiveMemoryWarning()
            // Dispose of any resources that can be recreated.
        }
}

