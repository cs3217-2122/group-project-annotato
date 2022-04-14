import UIKit

class ChangeOwnerListView: UITableView {
    let cellId = "ChangeOwnerListCell"

    private var users: [UserViewModel]
    private(set) var selectedUser: UserViewModel?

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(frame: CGRect, users: [UserViewModel]) {
        self.users = users

        super.init(frame: frame, style: .insetGrouped)
        dataSource = self
        delegate = self
        register(ChangeOwnerListCellView.self, forCellReuseIdentifier: cellId)
    }
}

extension ChangeOwnerListView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        users.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = dequeueReusableCell(
            withIdentifier: cellId, for: indexPath
        ) as? ChangeOwnerListCellView else {
            fatalError("unable to dequeue UsersSharingDocumentList cell")
        }

        cell.user = users[indexPath.row]
        cell.initializeSubviews()

        return cell
    }
}

extension ChangeOwnerListView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let tappedCell = cellForRow(at: indexPath) as? ChangeOwnerListCellView else {
            return
        }

        tappedCell.didTap()
        selectedUser = nil

        guard tappedCell.isSelected else {
            return
        }

        selectedUser = tappedCell.user

        guard let visibleCells = visibleCells as? [ChangeOwnerListCellView] else {
            return
        }

        for cell in visibleCells where cell !== tappedCell {
            cell.unselect()
        }
    }
}