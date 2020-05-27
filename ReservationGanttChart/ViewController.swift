//
//  ViewController.swift
//  ReservationGanttChart
//
//  Created by Hoang Luong on 26/5/20.
//  Copyright © 2020 Hoang Luong. All rights reserved.
//

import UIKit

struct GanttChartItem {
    let startDate: Date
    let endDate: Date
    var imageName: String?
    let mainString: String
    let contentString: String
}

class ViewController: UIViewController {

    @IBOutlet weak var monthLabel: UILabel!
    
    //  Layout constants
    let columnWidth: CGFloat = 40
    let pillHeight: CGFloat = 30
    let topMargin: CGFloat = 80
    let verticalSpacing: CGFloat = 10
    
    @IBOutlet weak var collectionView: UICollectionView!

    var dateRange = [Date]()
    var items = [GanttChartItem]()
    var gantItemViews = [UIView]()
    
    var selectedIndexPath: IndexPath?
    
    var topPillConstraint: NSLayoutConstraint?
    
    var currentZoomScale: CGFloat = 1.0 {
        didSet {
            collectionView.collectionViewLayout.invalidateLayout()
            gantItemViews.forEach( { $0.removeFromSuperview() })
            gantItemViews.removeAll()
            loadItemsIntoView()
        }
    }
    var minZoomScale: CGFloat = 0.75
    var maxZoomScale: CGFloat = 2.0
    
    var activePinchScale: CGFloat = 1.0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupDates()
        collectionView.register(UINib(nibName: "VerticalDateCell", bundle: nil), forCellWithReuseIdentifier: "verticalDateCellID")
        collectionView.register(VerticalDateCell.self, forCellWithReuseIdentifier: "identifier")
        collectionView.alwaysBounceVertical = false
        collectionView.alwaysBounceHorizontal = false
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        setupData()
        loadItemsIntoView()
        setupZoomGesture()
    }
    
    private func setupZoomGesture() {
        let gesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture))
        gesture.cancelsTouchesInView = false
        view.isMultipleTouchEnabled = true
        view.addGestureRecognizer(gesture)
    }
    
    @objc private func handlePinchGesture(sender: UIPinchGestureRecognizer) {
        if sender.scale > 1 {
            print("greater")
            print(sender.scale)
            let newScale = currentZoomScale + (sender.scale * 0.1)
            if newScale <= maxZoomScale {
                currentZoomScale = newScale
            }
        } else {
            let newScale = currentZoomScale - (1 - sender.scale) / 2
            print(sender.scale)
            print("less")
            if newScale >= minZoomScale {
                currentZoomScale = newScale
            }
        }
        
    }

    private func setupData() {
        let date = Date()
        /// Day 2 - 4
        items.append(GanttChartItem(startDate: Calendar.current.date(byAdding: .day, value: 1, to: date)!, endDate: Calendar.current.date(byAdding: .day, value: 4, to: date)!, imageName: nil, mainString: "Donald Trump", contentString: "$280, Standard Room"))
        /// Day 5 - 6
        items.append(GanttChartItem(startDate: Calendar.current.date(byAdding: .day, value: 4, to: date)!, endDate: Calendar.current.date(byAdding: .day, value: 6, to: date)!, imageName: nil,mainString: "Ken Watanabe", contentString: "$185, Eye of Sauron Suite"))
    }
    
    private func loadItemsIntoView() {
        for (num, item) in items.enumerated() {
            let startDate = Calendar.current.startOfDay(for: Date())
            let startColumn = Calendar.current.dateComponents([.day], from: startDate, to: item.startDate).day!
            let numDays = Calendar.current.dateComponents([.day], from: item.startDate, to: item.endDate).day!
            
            let ganttItem = GanttItemView()
            ganttItem.backgroundColor = .black
            collectionView.addSubview(ganttItem)
            ganttItem.layer.cornerRadius = pillHeight / 2
            ganttItem.layer.masksToBounds = true
            ganttItem.translatesAutoresizingMaskIntoConstraints = false
            if let previousItem = gantItemViews.last {
                ganttItem.topAnchor.constraint(equalTo: previousItem.bottomAnchor, constant: verticalSpacing).isActive = true
            } else {
                ganttItem.topAnchor.constraint(equalTo: collectionView.topAnchor, constant: topMargin).isActive = true
                
            }

            ganttItem.leadingAnchor.constraint(equalTo: collectionView.leadingAnchor, constant: columnWidth * currentZoomScale * CGFloat(startColumn)).isActive = true
            ganttItem.heightAnchor.constraint(equalToConstant: pillHeight).isActive = true
            ganttItem.widthAnchor.constraint(equalToConstant: columnWidth * currentZoomScale * CGFloat(numDays + 1)).isActive = true
            
            gantItemViews.append(ganttItem)
        }
    }
    
    private func setupDates() {
        var date = Date()
        while dateRange.count < 45 {
            dateRange.append(Calendar.current.startOfDay(for: date))
            date = Calendar.current.date(byAdding: .day, value: 1, to: date)!
        }
    }

}

extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        dateRange.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "verticalDateCellID", for: indexPath) as! VerticalDateCell
        cell.date = dateRange[indexPath.row]
        if selectedIndexPath == indexPath {
            cell.set(selected: true)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? VerticalDateCell {
            cell.set(selected: true)
            if let selectedIndexPath = selectedIndexPath, let previousSelectedCell = collectionView.cellForItem(at: selectedIndexPath) as? VerticalDateCell {
                previousSelectedCell.set(selected: false)
            }
            self.selectedIndexPath = indexPath
        }
    }
}

extension ViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: columnWidth * currentZoomScale, height: collectionView.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let indexPath = collectionView.indexPathForItem(at: view.convert(view.center, to: collectionView))
        let middleDate = dateRange[indexPath!.row]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM"
        monthLabel.text = dateFormatter.string(from: middleDate)
    }

}
