//
//  ViewController.swift
//  Apple-Weather
//
//  Created by 김윤서 on 2021/07/24.
//

import UIKit

import Moya
import SnapKit
import Then

class MainPageViewController: UIViewController {
    private lazy var service = MoyaProvider<WeatherAPI>()
    private var getWeather: GenericModel?
    
    private var viewControllerList: [MainViewController] = []
    public var weathers: [MainWeatherModel] = []
    public var myLocationWeather: [MainWeatherModel] = []
    
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
    
        requestGetWeather()
        setLayoutPageViewController()
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
    
    private func setPageViewController(index: Int) {
        pageViewController.setViewControllers([viewControllerList[index]], direction: .forward, animated: true, completion: nil)
        pageViewController.didMove(toParent: self)
        pageControl.currentPage = viewControllerList[index].view.tag
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
        
        dump(viewControllerList)
        
        let vc = MainViewController()
        vc.view.tag = 0
        vc.setData(weather: myLocationWeather[0])
        viewControllerList.append(vc)
        
        if weathers.count > 0 {
            for index in 0...weathers.count - 1 {
                viewControllerList.append(instantiateViewController(index: index))
            }
        }
        
        pageControl.numberOfPages = viewControllerList.count
        pageControl.setIndicatorImage(UIImage(systemName: "location.fill"), forPage: 0)
    }
    
    private func instantiateViewController(index: Int) -> MainViewController {
        let vc = MainViewController()
        vc.view.tag = index + 1
        vc.setData(weather: weathers[index])
        return vc
    }
    
    private func registerNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(didRecieveNotification(_:)), name: .addLocation, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didRecieveNotification(_:)), name: .deleteLocation, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didRecieveNotification(_:)), name: .selectLocation, object: nil)
    }
}

extension MainPageViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {

        guard let index = pageViewController.viewControllers?.first?.view.tag else { return nil }
       
        let previousIndex = index - 1
        
        if previousIndex < 0 || viewControllerList.count <= previousIndex {
            return nil
        }
        
        return viewControllerList[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        guard let index = pageViewController.viewControllers?.first?.view.tag else { return nil }
       
        let nextIndex = index + 1
        
        if viewControllerList.count <= nextIndex {
            return nil
        }
        
        return viewControllerList[nextIndex]
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
            locationListViewController.setData(myLocationWeather: myLocationWeather, weathers: weathers)
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
                weathers.remove(at: index)
            }
            setViewControllerList()
            setPageViewController(index: 0)
        case .selectLocation:
            if let  index = notification.object as? IndexPath {
                switch index.section {
                case 0:
                    setPageViewController(index: index.row)
                case 1:
                    setPageViewController(index: index.row + 1)
                default:
                    break
                }
            }
        default:
            break
        }
        
    }

}

extension MainPageViewController {

    func requestGetWeather() {
        service.request(WeatherAPI.getWeathers(lat: +37.28043530, lon: +127.11463210, exclude: "minutely")) { [weak self] result in
            switch result {
            case .success(let response):
                do {
                    
                    let response = try JSONDecoder().decode(GenericModel.self, from: response.data)
                    self?.getWeather = response
                    
                    self?.convertMainWeatherModel(response: response)
                } catch let err {
                    debugPrint(err)
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    func convertMainWeatherModel(response: GenericModel) {
        let now = Date()
        let date = DateFormatter()
        date.locale = Locale(identifier: "ko_KR")
        date.timeZone = TimeZone(identifier: "KST")
        date.dateFormat = "HH"
        
        let date2 = DateFormatter()
        date2.locale = Locale(identifier: "ko_KR")
        date2.timeZone = TimeZone(identifier: "KST")
        date2.dateFormat = "EEEE"
        
        var hourlyWeatherModel: [HourlyWeatherModel] = []
        var weekWeatherModel: [WeekWeaherModel] = []
        
        let hourly = response.hourly
        let daily = response.daily
        
        print("시간")
        print(date.string(from: now))
        
        for index in 0...23 {
            hourlyWeatherModel.append(HourlyWeatherModel(
                                        time: date.string(from: Date(timeIntervalSince1970: TimeInterval(hourly[index].dt))),
                                        icon: "cloud",
                                        temperature: Int(hourly[index].temp)))
        }
        
        print(response.hourly.count)
        
        for index in 0...response.daily.count - 1 {
            weekWeatherModel.append(WeekWeaherModel(
                                        day: date2.string(from: Date(timeIntervalSince1970: TimeInterval(response.daily[index].dt))),
                                        icon: "cloud",
                                        precipitation: 20,
                                        highTemperature: Int(daily[index].temp.max),
                                        lowTemperature: Int(daily[index].temp.min)))
        }
        
        myLocationWeather.append(MainWeatherModel(location: response.timezone,
                                                  weather: response.current.weather[0].main.rawValue,
                                                  temperature: Int(response.current.temp),
                                                  highTemperature: Int(daily[0].temp.max),
                                                  lowTemperatuer: Int(daily[0].temp.min),
                                                  hourlyWeather: hourlyWeatherModel,
                                                  dailyWeather: DailyWeatherModel(weekWeather: weekWeatherModel)
        ))
        setViewControllerList()
        setPageViewController(index: 0)
    }
}
