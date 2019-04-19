//
//  NewsTableViewController.swift
//  Headlines
//
//  Created by Ezequiel Becerra on 4/8/17.
//  Copyright © 2017 Ezequiel Becerra. All rights reserved.
//

import UIKit
import SafariServices
import ViewAnimator

class NewsTableViewController: UIViewController {
    
    var news: [News] = [] {
        didSet {
            newsViewModels.removeAll()
            filteredNewsViewModels.removeAll()
            news.forEach({ (n) in
                let viewModel = NewsCellViewModel(news: n)
                viewModel.delegate = self
                viewModel.dateStyle = preferredDateStyle
                newsViewModels.append(viewModel)
                filteredNewsViewModels.append(viewModel)
            })
        }
    }
    var hasRegisteredPreview = false
    var selectedNews: News?
    
    var preferredDateStyle: DateFormatter.Style = .none
    var trackContextFrom: ContentViewContextFrom?
    
    let reactionsService = ReactionsService()
    let contentViewsService = ContentViewsService()
    
    var newsViewModels: [NewsCellViewModel] = []
    var filteredNewsViewModels: [NewsCellViewModel] = []
    var newsDataSource: NewsTableViewControllerDataSource?
    var analyticsIdentifier: String?
    let userSettingsManager = UserSettingsManager()
    
    var tableView: UITableView?
    var paginationActivityView: UIActivityIndicatorView?

    var lastPage: Int = 1
    var isFetchingInitialNews: Bool = false
    
    // MARK: Private
    
    func endRefreshing() {
        if !ProcessInfo.processInfo.arguments.contains("mockRequests") {
            tableView?.refreshControl?.endRefreshing()
        }
    }
    
    func startRefreshing() {
        if !ProcessInfo.processInfo.arguments.contains("mockRequests") {
            tableView?.refreshControl?.beginRefreshing()
        }
    }
    
    func showControllerWithError(_ error: NSError) {
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        let alertController = UIAlertController(title: "Sorry",
                                                message: error.localizedDescription,
                                                preferredStyle: .alert)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func addReaction(_ currentReaction: String, toNews currentNews: News) {
        guard let n = filteredNewsViewModels.filter ({$0.news.identifier == currentNews.identifier}).first else {
            return
        }
        
        n.news.reactions = currentNews.reactions?.sorted(by: { $0.date < $1.date })
        
        if let i = filteredNewsViewModels.index(of: n) {
            
            guard let tableView = tableView else {
                return
            }
            
            let indexPathToReload = IndexPath(row: i, section: 0)
            tableView.reloadRows(at: [indexPathToReload], with: .none)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else {
            return
        }
        
        switch identifier {
        case "reaction":
            guard let nav = segue.destination as? UINavigationController,
                let vc = nav.topViewController as? ReactionPickerViewController,
                let newsViewModel = sender as? NewsCellViewModel else {
                    return
            }
            
            vc.news = newsViewModel.news
            nav.modalPresentationStyle = .formSheet
        
        case "filter":
            guard let vc = segue.destination as? FilterViewController else {
                return
            }

            let sources = FilterSourcesDataSource.sources(fromNews: news)
            let selectedSources = FilterSourcesDataSource.preSelectedSources(fromNewsViewModels: filteredNewsViewModels)
            vc.filterSourcesDataSource = FilterSourcesDataSource(sources: sources, preSelectedSources: selectedSources)
            
            let categories = FilterCategoriesDataSource.categories(fromNews: news)
            let categoriesDataSource = FilterCategoriesDataSource(withCategories: categories)
            categoriesDataSource.viewController = vc
            vc.filterCategoriesDataSource = categoriesDataSource
            
            vc.transitioningDelegate = self
            vc.modalPresentationStyle = .overFullScreen
            
        default:
            return
        }
    }
    
    @objc func handleLongPress(gesture: UILongPressGestureRecognizer!) {
        
        if gesture.state != .began {
            return
        }
        
        let p = gesture.location(in: tableView)
        
        guard let tableView = tableView else {
            return
        }
        
        guard let indexPath = tableView.indexPathForRow(at: p) else {
            return
        }
        
        let viewModel = filteredNewsViewModels[indexPath.row]
        
        let vc = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        vc.popoverPresentationController?.sourceView = tableView.cellForRow(at: indexPath)
        
        let shareAction = UIAlertAction(title: "Compartir Noticia", style: .default) { (_) in
            UIPasteboard.general.string = ShareCanillitapActivity.canillitappURL(fromNews: viewModel.news)
            vc.dismiss(animated: true, completion: nil)
        }
        vc.addAction(shareAction)
        
        let reactAction = UIAlertAction(title: "Agregar Reacción", style: .default) { [weak self] (_) in
            vc.dismiss(animated: false, completion: nil)
            self?.performSegue(withIdentifier: "reaction", sender: viewModel)
        }
        vc.addAction(reactAction)
        
        let cancelAction = UIAlertAction(title: "Cancelar", style: .cancel) { (_) in
            vc.dismiss(animated: true, completion: nil)
        }
        vc.addAction(cancelAction)
        
        present(vc, animated: true, completion: nil)
    }
    
    @objc func fetchNews() {
        guard let ds = self.newsDataSource else {
            return
        }
        
        self.startRefreshing()
        self.isFetchingInitialNews = true
        
        let success: ([News]) -> Void = { [unowned self] (result) in
            self.endRefreshing()
            self.isFetchingInitialNews = false
            
            self.news.removeAll()
            self.news.append(contentsOf: result)
            
            if ds.isFilterEnabled {
                if let whitelist = self.userSettingsManager.whitelistedSources {
                    if whitelist.count > 0 {
                        self.filteredNewsViewModels = self.newsViewModels.filter { whitelist.contains($0.source!) }
                    }
                }
            }

            guard let tableView = self.tableView else {
                return
            }
            
            tableView.reloadData()
            UIView.animate(
                views: tableView.visibleCells,
                animations: [AnimationType.from(direction: .right, offset: 10.0)],
                animationInterval: 0.1
            )
        }
        
        let fail: (NSError) -> Void = { [unowned self] (error) in
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(1)) {
                self.endRefreshing()
                self.isFetchingInitialNews = false
            }
                        
            self.showControllerWithError(error)
        }
        
        ds.fetchNews(page: 1, success: success, fail: fail)
    }

    func setupPullToRefreshControl() {
        //  Setup refresh control
        guard let tableView = tableView else {
            return
        }
        
        let refreshCtrl = UIRefreshControl()
        tableView.refreshControl = refreshCtrl
        
        refreshCtrl.tintColor = UIColor(red: 0.99, green: 0.29, blue: 0.39, alpha: 1.00)
        refreshCtrl.addTarget(self, action: #selector(fetchNews), for: .valueChanged)
        
        //  Had to set content offset because of UIRefreshControl bug
        //  http://stackoverflow.com/a/31224299/994129
        tableView.contentOffset = CGPoint(x: 0, y: -refreshCtrl.frame.size.height)
    }
    
    @objc func filterButtonTapped() {
        performSegue(withIdentifier: "filter", sender: self)
    }
    
    private func setupFilterButtonItem() {
        let filterImage = UIImage(named: "filter_icon")
        let filterButtonItem = UIBarButtonItem(
                image: filterImage,
                style: .plain,
                target: self,
                action: #selector(filterButtonTapped)
        )
        filterButtonItem.tintColor = UIColor.white
        navigationItem.rightBarButtonItem = filterButtonItem
    }
    
    private func setupTableView() {
        tableView = UITableView(frame: .zero, style: .plain)
        
        guard let tableView = tableView else {
            return
        }
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        // Constraints
        let leftConstraint = NSLayoutConstraint(item: tableView,
                                                attribute: .left,
                                                relatedBy: .equal,
                                                toItem: view,
                                                attribute: .left,
                                                multiplier: 1,
                                                constant: 0)
        
        let topConstraint = NSLayoutConstraint(item: tableView,
                                               attribute: .top,
                                               relatedBy: .equal,
                                               toItem: view,
                                               attribute: .top,
                                               multiplier: 1,
                                               constant: 0)
        
        let rightConstraint = NSLayoutConstraint(item: tableView,
                                                 attribute: .right,
                                                 relatedBy: .equal,
                                                 toItem: view,
                                                 attribute: .right,
                                                 multiplier: 1,
                                                 constant: 0)
        
        let bottomConstraint = NSLayoutConstraint(item: tableView,
                                                  attribute: .bottom,
                                                  relatedBy: .equal,
                                                  toItem: view,
                                                  attribute: .bottom,
                                                  multiplier: 1,
                                                  constant: 0)
        
        view.addConstraints([leftConstraint, topConstraint, rightConstraint, bottomConstraint])
        
        tableView.delegate = self
        tableView.dataSource = self
        
        // Register custom cell
        let nib = UINib(nibName: "NewsTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "cell")
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        
        guard let ds = self.newsDataSource else {
            return
        }
        
        if ds.shouldDisplayPullToRefreshControl {
            setupPullToRefreshControl()
        }
        
        if ds.isFilterEnabled {
            setupFilterButtonItem()
        }
        
        self.fetchNews()
    }
    
    @IBAction func unwindToNews(segue: UIStoryboardSegue) {
        guard let vc = segue.source as? ReactionPickerViewController else {
            return
        }
        
        guard let currentNews = vc.news,
            let selectedReaction = vc.selectedReaction else {
                return
        }
        
        let success: (URLResponse?, News?) -> Void = { [unowned self] (_, updatedNews) in
            guard let n = updatedNews else {
                return
            }
            self.addReaction(selectedReaction, toNews: n)
        }
        
        let fail: (Error) -> Void = { [weak self] err in
            
            let error = err as NSError
            
            if let s = self {
                s.showControllerWithError(error)
            }
        }
        
        reactionsService.postReaction(
            selectedReaction,
            atPost: currentNews.identifier,
            success: success,
            fail: fail
        )
    }
    
    @IBAction func unwindFromFilter(segue: UIStoryboardSegue) {
        guard let vc = segue.source as? FilterViewController else {
            return
        }
        
        guard let identifier = segue.identifier else {
            return
        }
        
        switch identifier {
        
        case "dismiss":
            return
            
        case "sourcesApply":
            guard let dataSource = vc.filterSourcesDataSource else {
                return
            }
            
            userSettingsManager.whitelistedSources = dataSource.selectedSources
            
            filteredNewsViewModels = newsViewModels.filter { dataSource.selectedSources.contains($0.source!) }
            
            guard let tableView = tableView else {
                return
            }
            
            UIView.transition(
                with: tableView,
                duration: 0.30,
                options: .transitionCrossDissolve,
                animations: { tableView.reloadData() },
                completion: nil
            )
            return
            
        case "categorySelected":
            guard let dataSource = vc.filterCategoriesDataSource else {
                return
            }
            
            if dataSource.selectedCategory == nil {
                filteredNewsViewModels = newsViewModels
            } else {
                filteredNewsViewModels = newsViewModels.filter { $0.news.category == dataSource.selectedCategory }
            }
            
            guard let tableView = tableView else {
                return
            }
            
            tableView.reloadData()
            tableView.scrollToRow(at: IndexPath(item: 0, section: 0), at: .top, animated: false)
            
            UIView.transition(
                with: tableView,
                duration: 0.30,
                options: .transitionCrossDissolve,
                animations: {},
                completion: nil
            )
            return
            
        default:
            return
        }
    }
    
}

// MARK: - UITableViewDataSource
extension NewsTableViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredNewsViewModels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            as? NewsTableViewCell else {
                return UITableViewCell()
        }
        
        let viewModel = filteredNewsViewModels[indexPath.row]
        
        cell.titleLabel.text = viewModel.title
        cell.sourceLabel.attributedText = viewModel.attributedSource
        cell.timeLabel.text = viewModel.timeString
        cell.reactionsDataSource = viewModel
        cell.reactionsDelegate = viewModel
        cell.viewModel = viewModel
        
        cell.newsImageView.contentMode = .center
        
        if let imgURL = viewModel.imageURL {
            cell.newsImageView.isHidden = false
            cell.newsImageView.sd_setImage(
                with: imgURL,
                placeholderImage: UIImage(named: "icon_placeholder_small"),
                options: [],
                completed: { (_, error, _, _) in
                    
                    if error != nil {
                        return
                    }
                    
                    cell.newsImageView.contentMode = .scaleAspectFill
            })
        } else {
            cell.newsImageView.isHidden = true
        }
        
        cell.reactionsCollectionView.isHidden = !viewModel.shouldShowReactions
        cell.reactionsHeightConstraint.constant = cell.reactionsCollectionView.isHidden ? 0 : 30
        cell.addReactionButton.isHidden = viewModel.shouldShowReactions
        cell.reactionsCollectionView.reloadData()
        
        return cell
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // This is not needed on screens without pagination
        guard let newsDataSource = newsDataSource, newsDataSource.isPaginationEnabled == true else {
            return
        }

        if indexPath.row == filteredNewsViewModels.count - 1 && !isFetchingInitialNews {

            paginationActivityView?.startAnimating()

            let success: (([News]) -> Void) = { [weak self] news in

                guard let strongSelf = self else {
                    return
                }

                strongSelf.paginationActivityView?.stopAnimating()

                strongSelf.lastPage += 1

                let viewModels = news.map({ [weak self] n -> NewsCellViewModel in
                    let viewModel = NewsCellViewModel(news: n)
                    viewModel.delegate = self
                    viewModel.dateStyle = self?.preferredDateStyle
                    return viewModel
                })

                var indexPaths = [IndexPath]()
                let startIndex = indexPath.row + 1
                let endIndex = startIndex + viewModels.count - 1

                for index in startIndex...endIndex {
                    let i = IndexPath(row: index, section: 0)
                    indexPaths.append(i)
                }

                tableView.beginUpdates()

                strongSelf.newsViewModels.append(contentsOf: viewModels)
                strongSelf.filteredNewsViewModels.append(contentsOf: viewModels)

                tableView.insertRows(at: indexPaths, with: .none)
                tableView.setContentOffset(tableView.contentOffset, animated: false)

                tableView.endUpdates()
            }

            let fail: ((NSError) -> Void) = {  [weak self] error in
                guard let strongSelf = self else {
                    return
                }

                strongSelf.paginationActivityView?.stopAnimating()
            }

            newsDataSource.fetchNews(page: lastPage+1, success: success, fail: fail)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
}

// MARK: - UITableViewDelegate
extension NewsTableViewController: UITableViewDelegate {

    private func trackOpenNews(_ news: News) {
        guard let contextFrom = trackContextFrom else {
            return
        }
        
        contentViewsService.postContentView(news.identifier, context: contextFrom, success: nil, fail: nil)
    }
    
    func openNews(_ news: News) {

        trackOpenNews(news)
        
        if userSettingsManager.shouldOpenNewsInsideApp {
            let vc = SFSafariViewController(url: news.url, entersReaderIfAvailable: true)
            vc.delegate = self
            self.selectedNews = news
            present(vc, animated: true, completion: nil)
        } else {
            UIApplication.shared.open(news.url, options: [:], completionHandler: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let n = filteredNewsViewModels[indexPath.row].news
        openNews(n)
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {

        guard let isPaginationEnabled = self.newsDataSource?.isPaginationEnabled else {
            return 0
        }

        return isPaginationEnabled ? 50 : 0
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let rect = CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: 50)
        let footerView = UIView(frame: rect)

        let activityView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        activityView.translatesAutoresizingMaskIntoConstraints = false

        footerView.addSubview(activityView)

        let centerXConstraint = NSLayoutConstraint(item: activityView,
                                                   attribute: .centerX,
                                                    relatedBy: .equal,
                                                    toItem: footerView,
                                                    attribute: .centerX,
                                                    multiplier: 1,
                                                    constant: 0)

        let centerYConstraint = NSLayoutConstraint(item: activityView,
                                                   attribute: .centerY,
                                                   relatedBy: .equal,
                                                   toItem: footerView,
                                                   attribute: .centerY,
                                                   multiplier: 1,
                                                   constant: 0)

        footerView.addConstraints([centerXConstraint, centerYConstraint])

        paginationActivityView = activityView
        return footerView
    }
}

// MARK: - NewsCellViewModelDelegate
extension NewsTableViewController: NewsCellViewModelDelegate {
    
    func newsViewModel(_ viewModel: NewsCellViewModel, didSelectReaction reaction: Reaction) {
        
        let success: (URLResponse?, News?) -> Void = { [unowned self] (response, updatedNews) in
            guard let n = updatedNews else {
                return
            }
            self.addReaction(reaction.reaction, toNews: n)
        }
        
        let fail: (Error) -> Void = { [unowned self] (err) in
            self.showControllerWithError(err as NSError)
        }
        
        reactionsService.postReaction(
            reaction.reaction,
            atPost: viewModel.news.identifier,
            success: success,
            fail: fail
        )
    }
    
    func newsViewModelDidSelectReactionPicker(_ viewModel: NewsCellViewModel) {
        performSegue(withIdentifier: "reaction", sender: viewModel)
    }
}

// MARK: - UIViewControllerTransitioningDelegate
extension NewsTableViewController: UIViewControllerTransitioningDelegate {

    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let animator = DimPresentAnimationController()
        animator.isPresenting = true
        return animator
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DimPresentAnimationController()
    }
}

// MARK: - SFSafariViewControllerDelegate
extension NewsTableViewController: SFSafariViewControllerDelegate {
    
    func safariViewController(_ controller: SFSafariViewController,
                              activityItemsFor URL: URL,
                              title: String?) -> [UIActivity] {
        
        guard let n = self.selectedNews else {
            return []
        }
        
        let activity = ShareCanillitapActivity(withNews: n)
        return [activity]
    }
}

// MARK: - TabbedViewController
extension NewsTableViewController: TabbedViewController {
    
    func tabbedViewControllerWasDoubleTapped() {
        guard let tableView = tableView else {
            return
        }
        
        tableView.setContentOffset(CGPoint.zero, animated: true)
    }
}

// MARK: - UIViewControllerPreviewingDelegate
extension NewsTableViewController: UIViewControllerPreviewingDelegate {
    
    private func setupPreview() {
        guard let tableView = tableView, hasRegisteredPreview == false else {
            return
        }
        
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: tableView)
        } else {
            let longPressRecognizer = UILongPressGestureRecognizer(
                target: self,
                action: #selector(self.handleLongPress)
            )
            
            longPressRecognizer.delaysTouchesBegan = true
            tableView.addGestureRecognizer(longPressRecognizer)
        }

        hasRegisteredPreview = true
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setupPreview()
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                           viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        guard let tableView = tableView else {
            return nil
        }
        
        guard let indexPath = tableView.indexPathForRow(at: location) else {
            return nil
        }
        
        let news = filteredNewsViewModels[indexPath.row].news
        
        let storyboard = UIStoryboard(name: "NewsPreview", bundle: nil)
        let vc: NewsPreviewViewController? = storyboard.instantiateInitialViewController() as? NewsPreviewViewController
        vc?.news = news
        vc?.newsViewController = self
        vc?.preferredContentSize = CGSize(width: 300, height: 300)
        selectedNews = news
        return vc
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                           commit viewControllerToCommit: UIViewController) {
        
        guard let url = selectedNews?.url else {
            return
        }
        
        let vc = SFSafariViewController(url: url, entersReaderIfAvailable: true)
        vc.delegate = self
        present(vc, animated: true, completion: nil)
    }
}
