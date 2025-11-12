//
//  SpendingStatisticViewController.swift
//  Spending-Manager
//
//  Created by  User on 04/11/2025.
// thong
import UIKit
import DGCharts

class SpendingStatisticViewController: UIViewController {
    @IBOutlet weak var PiecharVIew: UIView!
    
    private var pieChart: PieChartView!
    private var isShowingChiTieu = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPieChart()
        showChiTieu()
    }
    
    func setupPieChart() {
        pieChart = PieChartView(frame: PiecharVIew.bounds)
        pieChart.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        PiecharVIew.addSubview(pieChart)
    }
    
    @IBAction func tabChiTieuTapped(_ sender: UIButton) {
        isShowingChiTieu = true
        showChiTieu()
    }
    
    @IBAction func tabThuNhapTapped(_ sender: UIButton) {
        isShowingChiTieu = false
        showThuNhap()
    }
    
    func showChiTieu() {
        let spendingData = [
            PieChartDataEntry(value: 40, label: "Ăn uống"),
            PieChartDataEntry(value: 30, label: "Di chuyển"),
            PieChartDataEntry(value: 30, label: "Giải trí")
        ]
        updateChart(with: spendingData)
    }
    
    func showThuNhap() {
        let incomeData = [
            PieChartDataEntry(value: 50, label: "Lương"),
            PieChartDataEntry(value: 30, label: "Thưởng"),
            PieChartDataEntry(value: 20, label: "Khác")
        ]
        updateChart(with: incomeData)
    }
    
    func updateChart(with entries: [PieChartDataEntry]) {
        let dataSet = PieChartDataSet(entries: entries)
        dataSet.colors = ChartColorTemplates.material()
        
        let data = PieChartData(dataSet: dataSet)
        pieChart.data = data
    }
}
