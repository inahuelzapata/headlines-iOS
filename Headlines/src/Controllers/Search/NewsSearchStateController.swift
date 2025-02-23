//
//  NewsSearchStateController.swift
//  Canillitapp
//
//  Created by Marcos Griselli on 06/07/2018.
//  Copyright © 2018 Ezequiel Becerra. All rights reserved.
//

import UIKit

class NewsSearchStateController: UIViewController, UISearchResultsUpdating {

    private let service = NewsService()
    private var dataTask: URLSessionDataTask?
    private let dispatchQueue = DispatchQueue.global(qos: .utility)
    private var dispatchWorkItem: DispatchWorkItem?
    private var previousTerm: String?

    var didSelectSuggestion: (String) -> Void = { _ in }
    lazy var stateViewController = ContentStateViewController()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        add(stateViewController)
    }

    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text, !text.isEmpty else {
            dataTask?.cancel()
            return
        }

        if text == previousTerm { return }
        previousTerm = text
        dataTask?.cancel()
        if stateViewController.shownViewController is NewsSearchViewController {
            stateViewController.transition(to: .loading)
        }
        dataTask = service.fetchTags(tag: text, success: { [unowned self] tags in
            self.render(tags: tags, searchedTerm: text)
            }, fail: nil)
    }

    private func render(news: [News]?) {
        let storyboard = UIStoryboard(name: "Search", bundle: Bundle.main)
        let newsController = storyboard.instantiateViewController(
            withIdentifier: "NewsSearchViewController"
            ) as! NewsSearchViewController
        newsController.show(news: news)
        stateViewController.transition(to: .render(newsController))
    }

    private func render(tags: [Tag], searchedTerm: String) {
        let storyboard = UIStoryboard(name: "Search", bundle: Bundle.main)
        let termsTableController = storyboard.instantiateViewController(
            withIdentifier: "SuggestedTermsTableViewController"
            ) as! SuggestedTermsTableViewController
        termsTableController.tags = tags
        termsTableController.searchedTerm = searchedTerm
        termsTableController.didSelect = didSelectSuggestion
        stateViewController.transition(to: .render(termsTableController))
    }

    func fetch(term: String) {
        dataTask?.cancel()
        stateViewController.transition(to: .loading)

        self.dataTask = self.service.searchNews(
            term,
            success: self.render,
            fail: self.error
        )
    }

    private func error(_ error: NSError) {
        guard error.code == NSURLErrorCancelled else {
            let alert = UIAlertController(
                title: "Sorry",
                message: error.localizedDescription,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
    }
}
