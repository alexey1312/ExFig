import UIComponents
import UIKit

final class IllustrationsViewController: UIViewController {
    @IBOutlet private var stackView: UIStackView!

    override func viewDidLoad() {
        super.viewDidLoad()

        [
            UIImage.imgZeroEmpty,
            UIImage.imgZeroError,
            UIImage.imgZeroInternet,
        ].forEach {
            let imageView = UIImageView(image: $0)
            stackView.addArrangedSubview(imageView)
        }
    }
}
