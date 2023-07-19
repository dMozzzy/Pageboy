//
//  PatchedPageViewController.swift
//  Pageboy
//
//  Created by Arabia -IT on 8/25/19.
//

import UIKit

/// Fixes not updating dataSource on animated setViewControllers. See: https://stackoverflow.com/a/13253884/715593
internal class PatchedPageViewController: UIPageViewController {

    private var isSettingViewControllers = false

    private var controllersToUpdate: [UIViewController]?
    private var completionToRun: ((Bool) -> Void)?
    private var directionToRun: UIPageViewController.NavigationDirection = .forward

    override func setViewControllers(_ viewControllers: [UIViewController]?, direction: UIPageViewController.NavigationDirection, animated: Bool, completion: ((Bool) -> Void)? = nil) {

        guard !isSettingViewControllers else {
          controllersToUpdate = viewControllers
          completionToRun = completion
          directionToRun = direction
          return
        }
        isSettingViewControllers = true
        DispatchQueue.main.async {
          super.setViewControllers(viewControllers, direction: direction, animated: animated) { (isFinished) in
            if isFinished && animated {
              DispatchQueue.main.async {
                super.setViewControllers(viewControllers, direction: direction, animated: false, completion: { _ in
                  self.isSettingViewControllers = false
                  self.runUpdateOnDemandIfNecessery()
                })
              }
            } else {
              self.isSettingViewControllers = false
              self.runUpdateOnDemandIfNecessery()
            }
            completion?(isFinished)
          }
        }
    }

    private func runUpdateOnDemandIfNecessery() {
        guard controllersToUpdate != nil else {
          return
        }
        setViewControllers(controllersToUpdate, direction: directionToRun, animated: false) { [weak self] result in
            self?.completionToRun?(result)
            self?.controllersToUpdate = nil
        }
    }
}
