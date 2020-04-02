import UIKit

class StateViewController: UIViewController {

    // MARK: Properties

    @IBOutlet weak var tableView: UITableView!
    let cellIdentifier: String = "BarCell"
    var dustStates = [DustState]()

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self

        // MARK: HTTPRequest JSON
        fetchStates()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    // MARK: Private Methods

    private func updateMainView(dataSource: DustState) {
        DispatchQueue.main.async {
            if let view = self.view as? DustStateView {
                view.setData(dataSource: dataSource)
            }
        }
    }

    private func fetchStates() {
        let request = HTTPRequest()
        guard let url = URL(string: "https://dust10.herokuapp.com/api/dust-status") else { return }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.yyyyMMdd)

        request.getJSON(url: url, decoder: decoder) { (result: Result<DustStates, HTTPRequest.APIError>) in
            var dustState: DustState
            switch result {
            case .success(let dustStates):
                self.dustStates = dustStates.list
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                dustState = self.dustStates.first!
            case .failure(let error):
                print(error.localizedDescription)
                #warning("테스트 데이터")
                dustState = DustState(measuredTime: Date(), value: 314, originalGrade: 2)
            }
            self.updateMainView(dataSource: dustState)
        }
    }
}

extension StateViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dustStates.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! BarChartCell
        let dustState = self.dustStates[indexPath.row]

        cell.dustValue.text = String(dustState.value ?? 0)

        let multiplier: CGFloat = min(1.0, CGFloat(dustState.value ?? 0) / 200.0)
        cell.dustBarWidthConstraint = cell.dustBar.widthAnchor.constraint(equalTo: cell.contentView.widthAnchor, multiplier: multiplier)
        cell.dustBarWidthConstraint.isActive = true

        if let grade = GradeFactory.create(by: dustState.originalGrade) {
            cell.dustBar.backgroundColor = grade.color
        }

        return cell
    }
}
