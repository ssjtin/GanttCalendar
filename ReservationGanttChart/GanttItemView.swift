//
//  GanttItemView.swift
//  ReservationGanttChart
//
//  Created by Hoang Luong on 27/5/20.
//  Copyright © 2020 Hoang Luong. All rights reserved.
//
import UIKit

protocol ItemViewDelegate: class {
    func didTap(item: GanttItemView)
}

class GanttItemView: UIView {
    
    @IBOutlet var contentView: UIView!
    
    weak var delegate: ItemViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        commonInit()
    }
    
    private func commonInit() {
        let nibView = loadFromNib()
        nibView.frame = bounds
        addSubview(nibView)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(itemTapped))
        contentView.addGestureRecognizer(tapGesture)
    }
    
    @objc private func itemTapped() {
        delegate?.didTap(item: self)
    }
    
    func set(_ item: GanttChartItem) {
        if item.state > 9 {
            contentView.backgroundColor = UIColor(named: "attentionDark")
        }
    }
}

extension UIView {
    func loadFromNib() -> UIView {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: String(describing: type(of: self)), bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        view.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth, UIView.AutoresizingMask.flexibleHeight]
        return view
    }
}
