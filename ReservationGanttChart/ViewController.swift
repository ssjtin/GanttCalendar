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
    let state: Int
    
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

    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var monthLabel: UILabel!
    @IBOutlet weak var searchIcon: UIImageView!
    
    //  Layout constants
    let columnWidth: CGFloat = 40
    let pillHeight: CGFloat = 40
    let topMargin: CGFloat = 60
    let verticalSpacing: CGFloat = 10
    
    var verticalItemLimit: Int {
        switch activePinchScale {
        case 1.9...2.0: return 6
        case 1.7..<1.9: return 8
        case 1.5..<1.7: return 10
        case 1.2..<1.5: return 12
        case 0.9..<1.2: return 15
        case 0.5..<0.9: return 20
        default: return 15
        }
    }
    
    @IBOutlet weak var collectionView: UICollectionView!

    var dateRange = [Date]()
    var items = [GanttChartItem]()
    var gantItemViews = [(view: GanttItemView, heightConstraint: NSLayoutConstraint)]()
    
    var selectedIndexPath: IndexPath?
    
    var topConstraint: NSLayoutConstraint?
    
    var currentZoomScale: CGFloat = 1.0 {
        didSet {
            collectionView.collectionViewLayout.invalidateLayout()
            gantItemViews.forEach( { $0.view.removeFromSuperview() })
            gantItemViews.removeAll()
            self.topConstraint = nil
            loadItemsIntoView()
        }
    }
    var minZoomScale: CGFloat = 0.75
    var maxZoomScale: CGFloat = 2.0
    
    var activePinchScale: CGFloat = 1.0
    
    var hasScrolledInitially = false
    
    var visibleModalView: UIView?
    
    var darkModeOn = false

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
        
        if darkModeOn {
            headerView.backgroundColor = .black
            monthLabel.textColor = .white
            searchIcon.tintColor = .white
            navigationController?.navigationBar.backgroundColor = .black
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !hasScrolledInitially {
            let initialVisibleIndexPath = IndexPath(item: 8, section: 0)
            collectionView.scrollToItem(at: initialVisibleIndexPath, at: [.centeredHorizontally, .top], animated: false)
            hasScrolledInitially.toggle()
        }
        if let indexPath = middleIndexPath {
            collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
        }
    }
    
    /// Gesture Setup
    
    var isZooming: Bool = false
    var isSwiping: Bool = false
    
    private func setupZoomGesture() {
        let gesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture))
        gesture.cancelsTouchesInView = false
        view.isMultipleTouchEnabled = true
        view.addGestureRecognizer(gesture)
        
        let swipeGesture = UIPanGestureRecognizer(target: self, action: #selector(handleSwipeGesture))
        swipeGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(swipeGesture)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture))
        tapGesture.cancelsTouchesInView = false
        collectionView.addGestureRecognizer(tapGesture)
    }
    
    @objc private func handleTapGesture(sender: UITapGestureRecognizer) {
        if visibleModalView != nil {
            visibleModalView?.removeFromSuperview()
            collectionView.alpha = 1
            visibleModalView = nil
        }
    }
    
    var currentYOffset: CGFloat = 60
    
    @objc private func handleSwipeGesture(sender: UIPanGestureRecognizer) {
        guard !isZooming else { return }
        
        if sender.translation(in: nil) != .zero {
            isSwiping = true
        }
        
        let translationY = sender.translation(in: nil).y
        topConstraint?.constant  = -translationY + currentYOffset
        
        if sender.state == .cancelled || sender.state == .ended {
            currentYOffset = topConstraint?.constant ?? 0.0
        }
        
        if sender.state == .cancelled || sender.state == .failed {
            isSwiping = false
        }
    }
    
    var middleIndexPath: IndexPath?
    
    @objc private func handlePinchGesture(sender: UIPinchGestureRecognizer) {
        if sender.state == .began {
            isZooming = true
            middleIndexPath = collectionView.indexPathForItem(at: view.convert(view.center, to: collectionView))
        }
        
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
        
        if sender.state == .cancelled || sender.state == .ended {
            isZooming = false
            middleIndexPath = nil
        }
        
    }

    private func setupData() {
        let date = Date()
        /// Day 2 - 4
        items.append(GanttChartItem(startDate: Calendar.current.date(byAdding: .day, value: 1, to: date)!, endDate: Calendar.current.date(byAdding: .day, value: 4, to: date)!, imageName: nil, mainString: "Donald Trump", contentString: "$280, Standard Room", state: 0))
        /// Day 5 - 6
        items.append(GanttChartItem(startDate: Calendar.current.date(byAdding: .day, value: 4, to: date)!, endDate: Calendar.current.date(byAdding: .day, value: 6, to: date)!, imageName: nil,mainString: "Ken Watanabe", contentString: "$185, Eye of Sauron Suite", state: 0))
        
        for _ in 1...20 {
            let start = Int.random(in: 1...20)
            let duration = Int.random(in: 1...4)
            let stateInt = Int.random(in: 1...10)
            
            items.append(GanttChartItem(startDate: Calendar.current.date(byAdding: .day, value: start, to: date)!, endDate: Calendar.current.date(byAdding: .day, value: start + duration, to: date)!, imageName: nil, mainString: "Donald Trump", contentString: "$280, Standard Room", state: stateInt))
        }
        
        items.sort()
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
            ganttItem.set(item)
            ganttItem.delegate = self
            
            if let previousItem = gantItemViews.last {
                if (num > 0) && ((num + 1) % verticalItemLimit == 0) {
                    ganttItem.topAnchor.constraint(equalTo: gantItemViews.first!.view.topAnchor).isActive = true
                    
                } else {
                    ganttItem.topAnchor.constraint(equalTo: previousItem.view.bottomAnchor, constant: verticalSpacing).isActive = true
                }
                
            } else {
                let topAnchor = ganttItem.topAnchor.constraint(equalTo: collectionView.topAnchor, constant: topMargin + currentYOffset - 60)
                topAnchor.isActive = true
                topConstraint = topAnchor
                
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
            cell.set(selected: selectedIndexPath == indexPath, darkModeOn: darkModeOn)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "verticalDateCellID", for: indexPath) as! VerticalDateCell
        cell.date = dateRange[indexPath.row]
        if selectedIndexPath == indexPath {
            cell.set(selected: true, darkModeOn: darkModeOn)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? VerticalDateCell {
            cell.set(selected: true, darkModeOn: darkModeOn)
            if let selectedIndexPath = selectedIndexPath, let previousSelectedCell = collectionView.cellForItem(at: selectedIndexPath) as? VerticalDateCell {
                previousSelectedCell.set(selected: false, darkModeOn: darkModeOn)
            }
            self.selectedIndexPath = indexPath
            collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
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

extension ViewController: ItemViewDelegate {
    func didTap(item: GanttItemView) {
        showDetails(for: item)
    }
    
    func showDetails(for itemView: GanttItemView) {
        if visibleModalView != nil {
            visibleModalView?.removeFromSuperview()
        }
        
        let overlay = UIView()
        overlay.frame = collectionView.convert(itemView.frame, to: view)
        view.addSubview(overlay)
        overlay.backgroundColor = UIColor.black
        overlay.layer.cornerRadius = pillHeight / 2
        overlay.layer.masksToBounds = true
        overlay.backgroundColor = itemView.contentView.backgroundColor
        
        UIView.animate(withDuration: 0.3, animations: {
            overlay.frame.size = CGSize(width: 300, height: 300)
            overlay.center = self.view.center
            overlay.layer.cornerRadius = 8
            self.collectionView.alpha = 0.6
        }) { (_) in
            let contentView = UIView()
            overlay.addSubview(contentView)
            contentView.frame = overlay.bounds
            contentView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            contentView.backgroundColor = self.darkModeOn ? .black : .white
            contentView.layer.cornerRadius = 8
            contentView.alpha = 0
            
            let label = UILabel()
            label.text = "Shirley U Carnbeseerius"
            if self.darkModeOn { label.textColor = .white }
            
            label.translatesAutoresizingMaskIntoConstraints = false
            
            let contentLabel = UITextView()
            contentLabel.translatesAutoresizingMaskIntoConstraints = false
            contentLabel.text = "$1890 The Ritz Deluxe Family Room\n\nHere's some extra details and junk"
            if self.darkModeOn { contentLabel.textColor = .white }
            contentLabel.backgroundColor = .clear
            
            contentView.addSubview(label)
            contentView.addSubview(contentLabel)
            
            label.textColor = self.darkModeOn ? .white : .black
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10).isActive = true
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10).isActive = true
            label.heightAnchor.constraint(equalToConstant: 30).isActive = true
            label.widthAnchor.constraint(equalToConstant: 200).isActive = true
            label.backgroundColor = .clear
            
            
            contentLabel.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 0).isActive = true
            contentLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10).isActive = true
            contentLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10).isActive = true
            contentLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10).isActive = true
            
            UIView.animate(withDuration: 0.3) {
                contentView.alpha = 1
            }
            
        }
        visibleModalView = overlay
    }
}
