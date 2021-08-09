//
//  ViewController.swift
//  Apple-Weather
//
//  Created by 김윤서 on 2021/07/24.
//

import UIKit

import SnapKit
import Then

class MainPageViewController: UIViewController {
    
    private var viewControllerList: [MainViewController] = []
    public var weathers: [MainWeatherModel] = []
    
    private let pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
    
    private let pageControl = UIPageControl().then {
        $0.currentPageIndicatorTintColor = .white
        $0.pageIndicatorTintColor = .white.withAlphaComponent(0.3)
        $0.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private let toolbar = UIToolbar()

    private let backgroundImageView = UIImageView().then {
        $0.image = UIImage(named: "backImage")
    }
    
    private let seperatorView = UIView().then {
        $0.backgroundColor = .white
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setData()
        setLayoutPageViewController()
        setPageViewController()
        setViewControllerList()
        setPageControlBar()
        setTargets()
        
        registerNotification()
        
    }
    
    private func setLayoutPageViewController() {
        view.backgroundColor = UIColor(red: 0 / 255, green: 0 / 255, blue: 45 / 255, alpha: 1)
        
        pageViewController.dataSource = self
        pageViewController.delegate = self
         
        view.addSubviews(pageViewController.view, leftButton, toolbar, seperatorView)
        toolbar.snp.makeConstraints {
            $0.bottom.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            $0.height.equalTo(30)
        }
    
        seperatorView.snp.makeConstraints {
            $0.height.equalTo(Constants.Seperator.height)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(toolbar.snp.top)
        }

        addChild(pageViewController)

        pageViewController.view.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(toolbar.snp.top)
        }
       
    }
    
    private func setPageViewController() {
        pageViewController.setViewControllers([instantiateViewController(index: 0)], direction: .forward, animated: true, completion: nil)
        pageViewController.didMove(toParent: self)
   }
    
    private let leftButton = UIButton().then {
        $0.setImage(UIImage(systemName: "safari"), for: .normal)
    }
    
    private let rightButton = UIButton().then {
        $0.setImage(UIImage(systemName: "list.dash"), for: .normal)
    }
    
    private func setTargets() {
        leftButton.addTarget(self, action: #selector(tapButton(_:)), for: .touchUpInside)
        rightButton.addTarget(self, action: #selector(tapButton(_:)), for: .touchUpInside)
        pageControl.addTarget(self, action: #selector(pageControltapped(_:)), for: .valueChanged)
    }
    
    private func setPageControlBar() {
        let leftIcon = UIBarButtonItem(customView: leftButton)
        let rightIcon = UIBarButtonItem(customView: rightButton)
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        
        let pageControl = UIBarButtonItem(customView: pageControl)
        
        toolbar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
        toolbar.backgroundColor = .clear
        toolbar.tintColor = .white
        toolbar.setItems([leftIcon, flexibleSpace, pageControl, flexibleSpace, rightIcon], animated: true)
        
    }
    
    private func setViewControllerList() {
        viewControllerList.removeAll()
        for index in 0...weathers.count - 1 {
            viewControllerList.append(instantiateViewController(index: index))
        }
        
        pageControl.numberOfPages = viewControllerList.count
        pageControl.setIndicatorImage(UIImage(systemName: "location.fill"), forPage: 0)
    }
    
    private func instantiateViewController(index: Int) -> MainViewController {
        let vc = MainViewController()
        vc.view.tag = index
        vc.setData(weather: weathers[index])
        return vc
    }
    
    private func registerNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(didRecieveNotification(_:)), name: .addLocation, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didRecieveNotification(_:)), name: .deleteLocation, object: nil)
    }
}

extension MainPageViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        guard let index = pageViewController.viewControllers?.first?.view.tag else { return UIViewController() }

        let nextIndex = index > 0 ? index - 1 : viewControllerList.count - 1
        let nextVC = viewControllerList[nextIndex]
        return nextVC
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = pageViewController.viewControllers?.first?.view.tag else { return UIViewController() }
        
        let nextIndex = (index + 1) % viewControllerList.count
        let nextVC = viewControllerList[nextIndex]
        return nextVC
    }
    
}

extension MainPageViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
       guard completed else { return }
       
       if let vc = pageViewController.viewControllers?.first {
           pageControl.currentPage = vc.view.tag
       }
    }
    
}

extension MainPageViewController {
    @objc
    func pageControltapped(_ sender: UIPageControl) {
        pageViewController.setViewControllers([viewControllerList[sender.currentPage]], direction: .forward, animated: true, completion: nil)
    }
    
    @objc
    func tapButton(_ sender: UIButton) {
        switch sender {
        case leftButton:
            if let url = URL(string: "https://weather.com/ko-KR/weather/today/l/KSXX0037:1:KS?Goto=Redirected") {
                UIApplication.shared.open(url, options: [:])
            }
        case rightButton:
            let locationListViewController = LocationListViewController()
            locationListViewController.modalPresentationStyle = .overCurrentContext
            locationListViewController.setData(weathers: weathers)
            present(locationListViewController, animated: true, completion: nil)
            
        default:
            break
        }
    }
    
    @objc
    func didRecieveNotification(_ notification: Notification) {
        switch notification.name {
        case .addLocation:
            if let  object = notification.object as? MainWeatherModel {
                weathers.append(object)
            }
            setViewControllerList()
        case .deleteLocation:
            if let  index = notification.object as? Int {
                print(index)
                weathers.remove(at: index)
            }
            setViewControllerList()
        default:
            break
        }
        
    }

}
