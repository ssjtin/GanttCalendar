//
//  VerticalDateCell.swift
//  ReservationGanttChart
//
//  Created by Hoang Luong on 26/5/20.
//  Copyright © 2020 Hoang Luong. All rights reserved.
//

import UIKit

class VerticalDateCell: UICollectionViewCell {
    
    var borderColor: UIColor = .darkGray
    var borderWidth: CGFloat = 0.5
    var date: Date = Date() {
        didSet {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "d"
            dateLabel.text = dateFormatter.string(from: date)
            dateFormatter.dateFormat = "E"
            //TODO => Force unwrap
            dayLabel.text = String(dateFormatter.string(from: date).first!)
        }
    }
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var dayLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    
        self.layer.borderWidth = borderWidth
        self.layer.borderColor = borderColor.cgColor
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        backgroundColor = .white
    }
    func set(selected: Bool, darkModeOn: Bool) {
        backgroundColor = selected ? UIColor(named: "grayLightest") : darkModeOn ? .black : .white
        if darkModeOn {
            dateLabel.textColor = .white
            dayLabel.textColor = .white
        }
    }
  
}
