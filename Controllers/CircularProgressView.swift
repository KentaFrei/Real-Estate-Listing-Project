import UIKit

class CircularProgressView: UIView {

    private let shapeLayer = CAShapeLayer()
    private var currentProgress: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayer()
    }

    private func setupLayer() {
        shapeLayer.strokeColor = UIColor.systemBlue.cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineWidth = 6
        shapeLayer.lineCap = .round
        shapeLayer.strokeEnd = 0
        layer.addSublayer(shapeLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard bounds.width > 0 && bounds.height > 0 else { return }
        
        let circlePath = UIBezierPath(
            arcCenter: CGPoint(x: bounds.midX, y: bounds.midY),
            radius: min(bounds.width, bounds.height) / 2 - 5,
            startAngle: -.pi / 2,
            endAngle: .pi * 3 / 2,
            clockwise: true
        )
        
        // Disabilita animazioni implicite durante l'aggiornamento del path
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        shapeLayer.path = circlePath.cgPath
        shapeLayer.strokeEnd = currentProgress  
        CATransaction.commit()
    }

    func setProgress(_ value: CGFloat) {
        currentProgress = min(max(0, value), 1)
        shapeLayer.strokeEnd = currentProgress
    }
    
    func getProgress() -> CGFloat {
        return currentProgress
    }
    
    func reset() {
        currentProgress = 0
        shapeLayer.strokeEnd = 0
    }
}

