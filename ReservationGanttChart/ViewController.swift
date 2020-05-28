//
//  ViewController.swift
//  ReservationGanttChart
//
//  Created by Hoang Luong on 26/5/20.
//  Copyright © 2020 Hoang Luong. All rights reserved.
//

import UIKit

struct GanttChartItem: Comparable {
    let startDate: Date
    let endDate: Date
    var imageName: String?
    let mainString: String
    let contentString: String
    
    static func < (lhs: GanttChartItem, rhs: GanttChartItem) -> Bool {
        if lhs.startDate < rhs.startDate {
            return true
        } else if lhs.startDate == rhs.startDate && lhs.endDate < rhs.endDate {
            return true
        }
        
        return false
    }
}

class ViewController: UIViewController {

    @IBOutlet weak var monthLabel: UILabel!
    
    //  Layout constants
    let columnWidth: CGFloat = 40
    let pillHeight: CGFloat = 30
    let topMargin: CGFloat = 60
    let verticalSpacing: CGFloat = 10
    
    @IBOutlet weak var collectionView: UICollectionView!

    var dateRange = [Date]()
    var items = [GanttChartItem]()
    var gantItemViews = [(view: GanttItemView, heightConstraint: NSLayoutConstraint)]()
    
    var selectedIndexPath: IndexPath?
    
    var currentZoomScale: CGFloat = 1.0 {
        didSet {
            collectionView.collectionViewLayout.invalidateLayout()
            gantItemViews.forEach( { $0.view.removeFromSuperview() })
            gantItemViews.removeAll()
            loadItemsIntoView()
        }
    }
    var minZoomScale: CGFloat = 0.75
    var maxZoomScale: CGFloat = 2.0
    
    var activePinchScale: CGFloat = 1.0
    
    var hasScrolledInitially = false

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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !hasScrolledInitially {
            let initialVisibleIndexPath = IndexPath(item: 8, section: 0)
            collectionView.scrollToItem(at: initialVisibleIndexPath, at: .centeredHorizontally, animated: false)
            hasScrolledInitially.toggle()
        }
    }
    
    private func setupZoomGesture() {
        let gesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture))
        gesture.cancelsTouchesInView = false
        view.isMultipleTouchEnabled = true
        view.addGestureRecognizer(gesture)
    }
    
    @objc private func handlePinchGesture(sender: UIPinchGestureRecognizer) {
        if sender.scale > 1 {
            let newScale = currentZoomScale + (sender.scale * 0.1)
            if newScale <= maxZoomScale {
                currentZoomScale = newScale
            }
        } else {
            let newScale = currentZoomScale - (1 - sender.scale) / 2
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
        
        for _ in 1...20 {
            let start = Int.random(in: 1...15)
            let duration = Int.random(in: 1...4)
            
            items.append(GanttChartItem(startDate: Calendar.current.date(byAdding: .day, value: start, to: date)!, endDate: Calendar.current.date(byAdding: .day, value: start + duration, to: date)!, imageName: nil, mainString: "Donald Trump", contentString: "$280, Standard Room"))
        }
        
        items.sort()
    }
    
    private func loadItemsIntoView() {
        for item in items {
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
                ganttItem.topAnchor.constraint(equalTo: previousItem.view.bottomAnchor, constant: verticalSpacing).isActive = true
            } else {
                ganttItem.topAnchor.constraint(equalTo: collectionView.topAnchor, constant: topMargin).isActive = true
                
            }

            ganttItem.leadingAnchor.constraint(equalTo: collectionView.leadingAnchor, constant: columnWidth * currentZoomScale * CGFloat(startColumn + 7)).isActive = true
            let heightAnchor = ganttItem.heightAnchor.constraint(equalToConstant: pillHeight)
            heightAnchor.isActive = true
            
            ganttItem.widthAnchor.constraint(equalToConstant: columnWidth * currentZoomScale * CGFloat(numDays + 1 )).isActive = true
            
            gantItemViews.append((ganttItem, heightAnchor))
        }
    }
    
    private func setupDates() {
        var date = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
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
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? VerticalDateCell {
            cell.set(selected: selectedIndexPath == indexPath)
        }
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
            collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        }
    }
}

extension ViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: columnWidth * currentZoomScale, height: collectionView.frame.height * 2)
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
        
        //  Adjusting vertically visible chips
        
        
    }

}
