//
//  PlantsTableViewController.swift
//  Plants
//
//  Created by Alexander Supe on 02.02.20.
//

import UIKit
import CoreData

class PlantsTableViewController: UITableViewController {
    
    // MARK: - frc
    lazy var fetchedResultsController: NSFetchedResultsController<NewPlant> = {
        let fetchRequest: NSFetchRequest<NewPlant> = NewPlant.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "wateredDate", ascending: true)]
        let context = CoreDataStack.shared.mainContext
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        frc.delegate = self
        try! frc.performFetch()
        return frc
    }()
    
    // MARK: - Properties
    var newPlantController = NewPlantController.shared
    var nextDateString: String = ""
    var nextDate: Date? { didSet { UserController.keychain.set("\(self.nextDate!.timeIntervalSince1970.description)", forKey: "Date") } }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        UserController.keychain.delete("Date")
    }
    
    // MARK: - IBActions
    @IBAction func refresh(_ sender: Any) {
        newPlantController.read { (error) in
            if let error = error {
                //Handle error
                print("Error refreshing: \(error)")
                self.refreshControl?.endRefreshing()
            } else {
                self.tableView.reloadData()
                self.refreshControl?.endRefreshing()
            }
        }
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlantCell", for: indexPath) as! PlantsTableViewCell
        let plant = fetchedResultsController.object(at: indexPath)
        cell.nameLabel.text = plant.nickname
        
        if let image = plant.image { cell.imageView?.image = UIImage(data: image) }
        
        
        let interval = plant.h2oFrequency * 86400
        let date = (plant.wateredDate?.advanced(by: TimeInterval(interval)) ?? Date())
        if self.nextDate == nil || date < self.nextDate!{
            self.nextDate = date
        }
        
        let due: Bool = {if date < Date() { return true } else { return false }}()
        cell.timeLabel.text = due ? "Dehydrating since: \(DateHelper.getRelativeDate(date))" : "Next Watering: \(DateHelper.getRelativeDate(date))"
        cell.timeLabel.textColor = due ? .systemRed : .secondaryLabel
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowSegue", let destination = segue.destination as? PlantDetailViewController, let indexPath = tableView.indexPathForSelectedRow {
            destination.newPlant = fetchedResultsController.object(at: indexPath)
        }
    }
}

// MARK: - FetchedResultsControllerDelegate
extension PlantsTableViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .none)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .none)
        default:
            break
        }
    }
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            guard let newIndexPath = newIndexPath else { return }
            tableView.insertRows(at: [newIndexPath], with: .none)
        case .update:
            guard let indexPath = indexPath else { return }
            tableView.reloadRows(at: [indexPath], with: .none)
        case .move:
            guard let oldIndexPath = indexPath,
                let newIndexPath = newIndexPath else { return }
            tableView.deleteRows(at: [oldIndexPath], with: .none)
            tableView.insertRows(at: [newIndexPath], with: .none)
        case .delete:
            guard let indexPath = indexPath else { return }
            tableView.deleteRows(at: [indexPath], with: .none)
        @unknown default:
            break
        }
    }
}

