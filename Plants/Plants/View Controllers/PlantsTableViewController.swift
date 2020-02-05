//
//  PlantsTableViewController.swift
//  Plants
//
//  Created by Alexander Supe on 02.02.20.
//

import UIKit
import CoreData

class PlantsTableViewController: UITableViewController {
    
    lazy var fetchedResultsController: NSFetchedResultsController<NewPlant> = {
        let fetchRequest: NSFetchRequest<NewPlant> = NewPlant.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "h2oFrequency", ascending: true), NSSortDescriptor(key: "nickname", ascending: true)]
        let context = CoreDataStack.shared.mainContext
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: "h2oFrequency", cacheName: nil)
        frc.delegate = self
        try! frc.performFetch()
        return frc
    }()
    
    var newPlantController = NewPlantController.shared
    static var nextDate: String = ""
    var nextDate: Date? {
        didSet {
            UserController.keychain.set("\(PlantsTableViewController.nextDate)", forKey: "Date")
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
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
        
        if let image = plant.image {
            cell.imageView?.image = UIImage(data: image)
        }
        
        let interval = plant.h2oFrequency * 86400
        
        let nextDate = (plant.wateredDate?.advanced(by: TimeInterval(interval)) ?? Date())
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        
        if self.nextDate == nil || nextDate > self.nextDate!{
            self.nextDate = nextDate
            PlantsTableViewController.nextDate = formatter.string(for: nextDate) ?? ""
        }
        
        cell.timeLabel.text = "Next Watering: \(formatter.string(for: nextDate) ?? "")"
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let section = fetchedResultsController.sections?[section] else { return nil }
        if fetchedResultsController.sections?.count ?? 1 >= 1 {
            if section.name == "0" { return "Overdue" } }
        return "Plants"
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowSegue", let destination = segue.destination as? PlantDetailViewController, let indexPath = tableView.indexPathForSelectedRow {
            destination.newPlant = fetchedResultsController.object(at: indexPath)
        }
    }
}

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
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .automatic)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .automatic)
        default:
            break
        }
    }
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            guard let newIndexPath = newIndexPath else { return }
            tableView.insertRows(at: [newIndexPath], with: .automatic)
        case .update:
            guard let indexPath = indexPath else { return }
            tableView.reloadRows(at: [indexPath], with: .automatic)
        case .move:
            guard let oldIndexPath = indexPath,
                let newIndexPath = newIndexPath else { return }
            tableView.deleteRows(at: [oldIndexPath], with: .automatic)
            tableView.insertRows(at: [newIndexPath], with: .automatic)
        case .delete:
            guard let indexPath = indexPath else { return }
            tableView.deleteRows(at: [indexPath], with: .automatic)
        @unknown default:
            break
        }
    }
}
