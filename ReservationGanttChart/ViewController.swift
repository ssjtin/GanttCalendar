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
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    let columnWidth: CGFloat = 40
    let pillHeight: CGFloat = 30
    var dateRange = [Date]()
    var items = [GanttChartItem]()
    var gantItemViews = [UIView]()
    let pinchScrollView = UIScrollView()
    let dummyView = UIView()
    
    var topViewConstraint: NSLayoutConstraint!
    
    var zoomScale: CGFloat?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupDates()
        collectionView.register(UINib(nibName: "VerticalDateCell", bundle: nil), forCellWithReuseIdentifier: "verticalDateCellID")
        collectionView.register(VerticalDateCell.self, forCellWithReuseIdentifier: "identifier")
        collectionView.alwaysBounceVertical = false
        collectionView.alwaysBounceHorizontal = false
        
        if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.estimatedItemSize = .zero
        }
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        setupData()
        loadItemsIntoView()
        //setupZoom()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
//        pinchScrollView.contentSize = collectionView.collectionViewLayout.collectionViewContentSize
//        dummyView.frame = CGRect(origin: .zero, size: collectionView.collectionViewLayout.collectionViewContentSize)
//        pinchScrollView.frame = collectionView.frame
    }
    
    private func setupZoom() {
        //dummyView.backgroundColor = .gray
        //dummyView.alpha = 0.5
        view.addSubview(pinchScrollView)
        pinchScrollView.addSubview(dummyView)
        
        pinchScrollView.minimumZoomScale = 0.5
        pinchScrollView.maximumZoomScale = 1.5
        pinchScrollView.bouncesZoom = false
        pinchScrollView.delegate = self
    }
    
    private func setupData() {
        let date = Date()
        /// Day 2 - 4
        items.append(GanttChartItem(startDate: Calendar.current.date(byAdding: .day, value: 1, to: date)!, endDate: Calendar.current.date(byAdding: .day, value: 4, to: date)!, imageName: nil, mainString: "Donald Trump", contentString: "$280, Standard Room"))
        /// Day 5 - 6
        items.append(GanttChartItem(startDate: Calendar.current.date(byAdding: .day, value: 4, to: date)!, endDate: Calendar.current.date(byAdding: .day, value: 6, to: date)!, imageName: nil,mainString: "Ken Watanabe", contentString: "$185, Eye of Sauron Suite"))
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
            if let previousItemView = gantItemViews.last {
                ganttItem.topAnchor.constraint(equalTo: previousItemView.bottomAnchor, constant: 10).isActive = true
            } else {
                topViewConstraint = ganttItem.topAnchor.constraint(equalTo: collectionView.topAnchor, constant: pillHeight * 2 + 10)
                topViewConstraint.isActive = true
            }
            
            ganttItem.leadingAnchor.constraint(equalTo: collectionView.leadingAnchor, constant: columnWidth * CGFloat(startColumn)).isActive = true
            ganttItem.heightAnchor.constraint(equalToConstant: pillHeight).isActive = true
            ganttItem.widthAnchor.constraint(equalToConstant: columnWidth * CGFloat(numDays + 1)).isActive = true
            
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
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? VerticalDateCell {
            cell.set(selected: true)
        }
    }
}

extension ViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: columnWidth * (zoomScale ?? 1.0), height: collectionView.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

}

extension ViewController: UIScrollViewDelegate {
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        guard zoomScale != pinchScrollView.zoomScale else { return }
        zoomScale = scrollView.zoomScale
        
        topViewConstraint.constant = 90
        
        collectionView.setNeedsLayout()
        collectionView.layoutIfNeeded()
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.contentOffset = scrollView.contentOffset
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return dummyView
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        collectionView.contentOffset = scrollView.contentOffset
    }
}
