
//
//  ViewController.swift

import UIKit
import FSCalendar
import SwiftyJSON
import Alamofire

// 국경일, 공휴일,기념일 이름, 날짜, 간단한 설명을 저장하기 위한 구조체
struct Data {
    var name: String
    var date: String
}

struct RGB {
    var backR: CGFloat
    var backG: CGFloat
    var backB: CGFloat
}

class ViewController: UIViewController {

    @IBOutlet weak var calendarView: FSCalendar!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    // web으로부터 가져온 공휴일 정보를 저장하기 위한 배열
    var holidays: [Data] = []
    var rests: [Data] = []
    var anniversaries: [Data] = []
    
    let holiColor = RGB(backR: 0.97, backG: 0.61, backB: 0.69)  // pink
    let restColor = RGB(backR: 0.55, backG: 0.71, backB: 0.85)  // blue
    let anniColor = RGB(backR: 0.36, backG: 0.69, backB: 0.65) // green
    
    let dateFormatter = DateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 2021년 공휴일 정보 가져오기
        requestToDataPortal(year: "2021", operation: "HoliDeInfo")
        requestToDataPortal(year: "2021", operation: "RestDeInfo")
        requestToDataPortal(year: "2021", operation: "AnniversaryInfo")
        
        // calendarView의 속성 설정
        calendarView.appearance.titleWeekendColor = UIColor.red // 주말은 빨간 글씨로 표시
        calendarView.appearance.todayColor = UIColor.orange // 오늘 날짜는 오렌지 동그라미로 채우기
        calendarView.appearance.selectionColor = UIColor.black // 선택된 날짜는 검은 동그라미로 채우기
        calendarView.appearance.titleSelectionColor = UIColor.white // 선택된 날짜의 글씨는 하얀색으로 표시
        
        calendarView.delegate = self
        calendarView.dataSource = self
        
        dateFormatter.dateFormat = "yyyyMMdd"
        
    }

}


extension ViewController: FSCalendarDelegate, FSCalendarDataSource, FSCalendarDelegateAppearance {
    
    // 공휴일에 해당되는 날짜는 오렌지 색상의 동그라미로 채우기
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, fillDefaultColorFor date: Date) -> UIColor? {

        let dateStr = dateFormatter.string(from: date)
        for holiday in self.holidays {
            if holiday.date.compare(dateStr) == ComparisonResult.orderedSame {
                let color = UIColor(red: holiColor.backR, green: holiColor.backG, blue: holiColor.backB, alpha: 1)
                return color
            }
        }
        for rest in self.rests {
            if rest.date.compare(dateStr) == ComparisonResult.orderedSame {
                let color =  UIColor(red: restColor.backR, green: restColor.backG, blue: restColor.backB, alpha: 1)
                return color
            }
        }
        for anniversary in self.anniversaries {
            if anniversary.date.compare(dateStr) == ComparisonResult.orderedSame {
                let color =  UIColor(red: anniColor.backR, green: anniColor.backG, blue: anniColor.backB, alpha: 1)
                return color
            }
        }
        return nil
    }
    
    // 공휴일에 해당되는 날짜의 subtitle에 공휴일 이름 출력
//    func calendar(_ calendar: FSCalendar, subtitleFor date: Date) -> String? {
//
//        let dateStr = dateFormatter.string(from: date)
//        for holiday in self.holidays {
//            if holiday.date.compare(dateStr) == ComparisonResult.orderedSame {
//                return holiday.name
//            }
//        }
//        for rest in self.rests {
//            if rest.date.compare(dateStr) == ComparisonResult.orderedSame {
//                return rest.name
//            }
//        }
//        for anniversary in self.anniversaries {
//            if anniversary.date.compare(dateStr) == ComparisonResult.orderedSame {
//                return anniversary.name
//            }
//        }
//        return nil
//    }
    
    // 공휴일에 해당되는 날짜 선택시 descriptionLable에 공휴일 이름, 날짜, 간단한 설명 출력
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {

        var dateStr = dateFormatter.string(from: date)
        
        let descDateFormatter = DateFormatter()
        descDateFormatter.dateFormat = "yyyy.MM.dd"
       
        
        for holiday in self.holidays {
            if holiday.date.compare(dateStr) == ComparisonResult.orderedSame {
                OperationQueue.main.addOperation {
                    dateStr = descDateFormatter.string(from: date)
                    self.descriptionLabel.text = dateStr + "  " + holiday.name
                    return
                }
            }
        }
        for rest in self.rests {
            if rest.date.compare(dateStr) == ComparisonResult.orderedSame {
                OperationQueue.main.addOperation {
                    dateStr = descDateFormatter.string(from: date)
                    self.descriptionLabel.text = dateStr + "  " + rest.name
                    return
                }
            }
        }
        for anniversary in self.anniversaries {
            if anniversary.date.compare(dateStr) == ComparisonResult.orderedSame {
                OperationQueue.main.addOperation {
                    dateStr = descDateFormatter.string(from: date)
                    self.descriptionLabel.text = dateStr + "  " + anniversary.name
                    return
                }            }
        }
        self.descriptionLabel.text = ""
    }
    
    // Alamofire을 이용하여 calendarific 사이트에서 원하는 연도의 공휴일 정보 가져오기
    func requestToDataPortal(year: String, operation: String) {
        
        let baseURLStr = "http://apis.data.go.kr/B090041/openapi/service/SpcdeInfoService"
        let opName = "/get" + operation
        var apiKey = "wBhaQUZpErIgwSq6AnbVKeZ5UB8jlRCf1lTeC1HoHS8uvTM33TNSyZehs80krSxuCcOz4BnikqRvSbALw30tTg%3D%3D"
        apiKey = apiKey.removingPercentEncoding!
        
        let params = ["solYear": year, "ServiceKey": apiKey, "_type": "json"]
        
        Alamofire.request(baseURLStr+opName, method: .get, parameters: params, encoding: URLEncoding.default)
            .validate(statusCode: 200..<300)
            .responseData {
                (response) in
                switch response.result {
                case .success(let value):
                    if let jsonStr = String(data: value, encoding: .utf8) {
                        let jsonObject = JSON(parseJSON: jsonStr)
                        let count = jsonObject["response"]["body"]["items"]["item"].count
                        var arr: [Data] = []
                        
                        for i in 0..<count {
                            let dateName = jsonObject["response"]["body"]["items"]["item"][i]["dateName"].stringValue  // 공휴일 이름
                            let locdate = jsonObject["response"]["body"]["items"]["item"][i]["locdate"].intValue // 공휴일 날짜
                            let data = Data(name: dateName, date: String(locdate))
                            arr.append(data)
                        }
                        
                        switch operation {
                        case "HoliDeInfo":
                            self.holidays = arr
                        case "RestDeInfo":
                            self.rests = arr
                        case "AnniversaryInfo":
                            self.anniversaries = arr
                        default:
                            print("default")
                        }
                        
                        self.calendarView.reloadData()

                    } else {
                        print("error in json")
                    }
                case .failure(let error):
                    print(error)
                }
        }
        
    }
    
}

