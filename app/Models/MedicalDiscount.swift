import Foundation
import MapKit

struct MedicalDiscount: Identifiable, Codable, Hashable {
    let id = UUID()
    let category: String
    let hospitalName: String
    let eligiblePersons: String
    let specialtyMedicine: String
    let discountItems: String
    let address: String
    let phone: String
    let googleMapsURL: String
    
    enum CodingKeys: String, CodingKey {
        case category = "類別"
        case hospitalName = "醫院/診所名稱"
        case eligiblePersons = "優惠對象"
        case specialtyMedicine = "特色醫療"
        case discountItems = "優惠項目"
        case address = "住址"
        case phone = "電話"
        case googleMapsURL = "Google Maps"
    }
    
    /// 簡化的優惠描述（用於列表顯示）
    var shortDiscountDescription: String {
        let items = discountItems.components(separatedBy: "\n")
        if let firstItem = items.first {
            let cleanItem = firstItem.replacingOccurrences(of: "1. ", with: "")
                                   .replacingOccurrences(of: "2. ", with: "")
                                   .replacingOccurrences(of: "3. ", with: "")
            return cleanItem.count > 30 ? String(cleanItem.prefix(30)) + "..." : cleanItem
        }
        return "請洽詢診所"
    }
    
    /// 獲取醫院類型的圖標
    var categoryIcon: String {
        switch category {
        case "綜合醫院":
            return "building.2"
        case "外科":
            return "staroflife"
        case "牙科":
            return "mouth"
        case "中醫":
            return "leaf"
        case "眼科":
            return "eye"
        case "皮膚科":
            return "hand.raised"
        case "家醫科":
            return "person.fill.badge.plus"
        case "耳鼻喉科":
            return "ear"
        case "胸腔內科", "內科":
            return "lungs"
        case "身心科":
            return "brain.head.profile"
        case "骨科", "骨科/聯合":
            return "figure.walk"
        default:
            return "cross.case"
        }
    }
    
    /// 獲取優惠等級顏色
    var discountLevel: DiscountLevel {
        let text = discountItems.lowercased()
        if text.contains("免收掛號費") || text.contains("免掛號費") {
            return .high
        } else if text.contains("九折") || text.contains("八折") || text.contains("七折") {
            return .medium
        } else if text.contains("九五折") || text.contains("優惠") {
            return .low
        }
        return .basic
    }
    
    enum DiscountLevel {
        case high, medium, low, basic
        
        var color: String {
            switch self {
            case .high: return "green"
            case .medium: return "orange"
            case .low: return "blue"
            case .basic: return "gray"
            }
        }
        
        var text: String {
            switch self {
            case .high: return "優惠多"
            case .medium: return "有折扣"
            case .low: return "小優惠"
            case .basic: return "基本"
            }
        }
    }
    
    /// 获取医疗院所的精确坐标位置（基于台中地区）
    var coordinate: CLLocationCoordinate2D {
        // 根据医院名称返回固定的精确坐标，避免位置乱跳
        switch hospitalName {
        case let name where name.contains("中國醫藥大學附設醫院"):
            return CLLocationCoordinate2D(latitude: 24.1518, longitude: 120.6839)
        case let name where name.contains("宏恩醫院") && name.contains("龍安"):
            return CLLocationCoordinate2D(latitude: 24.1180, longitude: 120.6480)
        case let name where name.contains("宏恩醫院"):
            return CLLocationCoordinate2D(latitude: 24.1200, longitude: 120.6500)
        case let name where name.contains("新菩提醫院"):
            return CLLocationCoordinate2D(latitude: 24.0990, longitude: 120.6820)
        case let name where name.contains("澄清綜合醫院"):
            return CLLocationCoordinate2D(latitude: 24.1420, longitude: 120.6818)
        case let name where name.contains("臺中醫院"):
            return CLLocationCoordinate2D(latitude: 24.1469, longitude: 120.6839)
        case let name where name.contains("臺中榮民總醫院"):
            return CLLocationCoordinate2D(latitude: 24.1797, longitude: 120.6478)
        case let name where name.contains("彰化基督教醫院"):
            return CLLocationCoordinate2D(latitude: 24.0518, longitude: 120.5186)
        case let name where name.contains("童綜合醫院"):
            return CLLocationCoordinate2D(latitude: 24.2542, longitude: 120.5473)
        case let name where name.contains("秀傳紀念醫院"):
            return CLLocationCoordinate2D(latitude: 24.0518, longitude: 120.5186)
        // 具体诊所的固定坐标
        case let name where name.contains("羅倫檭診所"):
            return CLLocationCoordinate2D(latitude: 24.1280, longitude: 120.6750)
        case let name where name.contains("薇風整形外科"):
            return CLLocationCoordinate2D(latitude: 24.1300, longitude: 120.6770)
        case let name where name.contains("台全聯合診所"):
            return CLLocationCoordinate2D(latitude: 24.1450, longitude: 120.6820)
        case let name where name.contains("醫世紀診所"):
            return CLLocationCoordinate2D(latitude: 24.1440, longitude: 120.6800)
        case let name where name.contains("慶燿診所"):
            return CLLocationCoordinate2D(latitude: 24.1320, longitude: 120.6730)
        case let name where name.contains("恆宇診所"):
            return CLLocationCoordinate2D(latitude: 24.1325, longitude: 120.6735)
        case let name where name.contains("富台診所"):
            return CLLocationCoordinate2D(latitude: 24.1380, longitude: 120.6880)
        case let name where name.contains("禾安診所"):
            return CLLocationCoordinate2D(latitude: 24.2540, longitude: 120.7200)
        case let name where name.contains("欣欣成人小兒耳鼻喉科"):
            return CLLocationCoordinate2D(latitude: 24.1290, longitude: 120.6760)
        case let name where name.contains("白耳鼻喉科"):
            return CLLocationCoordinate2D(latitude: 24.1360, longitude: 120.6850)
        case let name where name.contains("李榮龍內科"):
            return CLLocationCoordinate2D(latitude: 24.1310, longitude: 120.6740)
        case let name where name.contains("永佳診所"):
            return CLLocationCoordinate2D(latitude: 24.1290, longitude: 120.6780)
        case let name where name.contains("豐田診所"):
            return CLLocationCoordinate2D(latitude: 24.1270, longitude: 120.6720)
        case let name where name.contains("新生牙醫"):
            return CLLocationCoordinate2D(latitude: 24.1285, longitude: 120.6745)
        case let name where name.contains("澄新牙醫"):
            return CLLocationCoordinate2D(latitude: 24.1365, longitude: 120.6855)
        case let name where name.contains("宜康牙醫"):
            return CLLocationCoordinate2D(latitude: 24.1315, longitude: 120.6725)
        case let name where name.contains("嘉仁牙醫"):
            return CLLocationCoordinate2D(latitude: 24.1275, longitude: 120.6715)
        case let name where name.contains("新世代中醫"):
            return CLLocationCoordinate2D(latitude: 24.1390, longitude: 120.6890)
        case let name where name.contains("酉安中醫"):
            return CLLocationCoordinate2D(latitude: 24.1295, longitude: 120.6765)
        case let name where name.contains("祥鶴中醫"):
            return CLLocationCoordinate2D(latitude: 24.1395, longitude: 120.6895)
        case let name where name.contains("北大中醫"):
            return CLLocationCoordinate2D(latitude: 24.1355, longitude: 120.6845)
        case let name where name.contains("明選眼科"):
            return CLLocationCoordinate2D(latitude: 24.1340, longitude: 120.6820)
        case let name where name.contains("達明眼科"):
            return CLLocationCoordinate2D(latitude: 24.0995, longitude: 120.6825)
        case let name where name.contains("漸漸身心"):
            return CLLocationCoordinate2D(latitude: 24.1400, longitude: 120.6900)
        default:
            // 默认台中市中心位置
            return CLLocationCoordinate2D(latitude: 24.1477, longitude: 120.6736)
        }
    }
    
    /// 获取地图标注
    var mapAnnotation: MedicalDiscountAnnotation {
        return MedicalDiscountAnnotation(
            coordinate: coordinate,
            title: hospitalName,
            subtitle: category,
            discount: self
        )
    }
}

// MARK: - Map Annotation
class MedicalDiscountAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?
    let discount: MedicalDiscount
    
    init(coordinate: CLLocationCoordinate2D, title: String, subtitle: String, discount: MedicalDiscount) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.discount = discount
        super.init()
    }
}

// MARK: - Sample Data
extension MedicalDiscount {
    static let sampleDiscounts: [MedicalDiscount] = [
        MedicalDiscount(
            category: "綜合醫院",
            hospitalName: "中國醫藥大學附設醫院",
            eligiblePersons: "教職員工、學生",
            specialtyMedicine: "世界一流醫學中心，各科專業醫療",
            discountItems: "1. 住院：病房費自費項目九五折優待\n2. 各項醫療費用九五折優待",
            address: "臺中市北區育德路2號",
            phone: "04-22052121",
            googleMapsURL: "https://www.google.com/maps/search/?api=1&query=中國醫藥大學附設醫院"
        ),
        MedicalDiscount(
            category: "牙科",
            hospitalName: "澄新牙醫診所",
            eligiblePersons: "教職員工、學生",
            specialtyMedicine: "家庭牙醫、植牙、矯正、兒童牙科",
            discountItems: "1. 門診免收掛號費\n2. 需自付部分負擔\n3. 看診請先預約",
            address: "臺中市南區學府路58號",
            phone: "04-22859898",
            googleMapsURL: "https://www.google.com/maps/search/?api=1&query=澄新牙醫診所"
        )
    ]
}
