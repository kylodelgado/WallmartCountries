//
//  CountriesApp.swift
//  WalmartCountriesAssessment
//
//  Created by Brandon on 3/10/25.
//

import UIKit

// MARK: - Models

struct Country: Codable {
    let name: String
    let region: String
    let code: String
    let capital: String
}

// MARK: - Main View Controller

class CountriesViewController: UIViewController {
    
    // MARK: - Properties
    private let tableView = UITableView()
    private var countries: [Country] = []
    private var filteredCountries: [Country] = []
    private let searchController = UISearchController(searchResultsController: nil)
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupSearchController()
        setupTableView()
        setupActivityIndicator()
        fetchCountries()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        title = "Countries"
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search by name or capital"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        tableView.register(CountryTableViewCell.self, forCellReuseIdentifier: "CountryCell")
        tableView.dataSource = self
        tableView.delegate = self
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    private func setupActivityIndicator() {
        view.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        activityIndicator.hidesWhenStopped = true
    }
    
    // MARK: - Data Fetching
    private func fetchCountries() {
        activityIndicator.startAnimating()
        
        guard let url = URL(string: "https://gist.githubusercontent.com/peymano-wmt/32dcb892b06648910ddd40406e37fdab/raw/db25946fd77c5873b0303b858e861ce724e0dcd0/countries.json") else {
            showAlert(title: "Error", message: "Invalid URL")
            activityIndicator.stopAnimating()
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.tableView.refreshControl?.endRefreshing()
                
                if let error = error {
                    self.showAlert(title: "Network Error", message: error.localizedDescription)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    self.showAlert(title: "Server Error", message: "Received invalid response from server")
                    return
                }
                
                guard let data = data else {
                    self.showAlert(title: "Data Error", message: "No data received")
                    return
                }
                
                do {
                    let countries = try JSONDecoder().decode([Country].self, from: data)
                    self.countries = countries
                    self.filteredCountries = countries
                    self.tableView.reloadData()
                } catch {
                    self.showAlert(title: "Parsing Error", message: "Failed to parse country data: \(error.localizedDescription)")
                }
            }
        }.resume()
    }
    
    @objc private func refreshData() {
        fetchCountries()
    }
    
    // MARK: - Helper Methods
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func filterCountries(for searchText: String) {
        if searchText.isEmpty {
            filteredCountries = countries
        } else {
            filteredCountries = countries.filter { country in
                return country.name.lowercased().contains(searchText.lowercased()) ||
                       country.capital.lowercased().contains(searchText.lowercased())
            }
        }
        tableView.reloadData()
    }
}

// MARK: - TableView DataSource & Delegate
extension CountriesViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredCountries.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CountryCell", for: indexPath) as? CountryTableViewCell else {
            return UITableViewCell()
        }
        
        let country = filteredCountries[indexPath.row]
        cell.configure(with: country)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let country = filteredCountries[indexPath.row]
        let detailVC = CountryDetailViewController(country: country)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

// MARK: - Search Results Updating
extension CountriesViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text {
            filterCountries(for: searchText)
        }
    }
}

// MARK: - Country Table View Cell
class CountryTableViewCell: UITableViewCell {
    
    // MARK: - UI Elements
    private let boxView = UIView()
    private let nameRegionLabel = UILabel()
    private let codeLabel = UILabel()
    private let capitalLabel = UILabel()
    private let topBorder = CAShapeLayer()
    private let bottomBorder = CAShapeLayer()
    private let leftBorder = CAShapeLayer()
    private let rightBorder = CAShapeLayer()
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setupBorders()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        // Box container setup
        contentView.addSubview(boxView)
        boxView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            boxView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            boxView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            boxView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            boxView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
        
        // Labels setup
        nameRegionLabel.numberOfLines = 0
        nameRegionLabel.font = .systemFont(ofSize: 16)
        
        codeLabel.font = .systemFont(ofSize: 16)
        codeLabel.textAlignment = .right
        
        capitalLabel.numberOfLines = 0
        capitalLabel.font = .systemFont(ofSize: 16)
        
        // Add labels to box
        boxView.addSubview(nameRegionLabel)
        boxView.addSubview(codeLabel)
        boxView.addSubview(capitalLabel)
        
        // Layout constraints
        nameRegionLabel.translatesAutoresizingMaskIntoConstraints = false
        codeLabel.translatesAutoresizingMaskIntoConstraints = false
        capitalLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            nameRegionLabel.topAnchor.constraint(equalTo: boxView.topAnchor, constant: 12),
            nameRegionLabel.leadingAnchor.constraint(equalTo: boxView.leadingAnchor, constant: 12),
            nameRegionLabel.trailingAnchor.constraint(equalTo: codeLabel.leadingAnchor, constant: -8),
            
            codeLabel.topAnchor.constraint(equalTo: boxView.topAnchor, constant: 12),
            codeLabel.trailingAnchor.constraint(equalTo: boxView.trailingAnchor, constant: -12),
            codeLabel.widthAnchor.constraint(equalToConstant: 50),
            
            capitalLabel.topAnchor.constraint(equalTo: nameRegionLabel.bottomAnchor, constant: 12),
            capitalLabel.leadingAnchor.constraint(equalTo: boxView.leadingAnchor, constant: 12),
            capitalLabel.trailingAnchor.constraint(equalTo: boxView.trailingAnchor, constant: -12),
            capitalLabel.bottomAnchor.constraint(equalTo: boxView.bottomAnchor, constant: -12)
        ])
    }
    
    private func setupBorders() {
        // Remove existing borders
        boxView.layer.sublayers?.removeAll(where: { $0 is CAShapeLayer })
        
        // Create path for dashed borders
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: boxView.bounds.width, y: 0))
        path.addLine(to: CGPoint(x: boxView.bounds.width, y: boxView.bounds.height))
        path.addLine(to: CGPoint(x: 0, y: boxView.bounds.height))
        path.close()
        
        // Create dashed border layer
        let borderLayer = CAShapeLayer()
        borderLayer.path = path.cgPath
        borderLayer.strokeColor = UIColor.gray.cgColor
        borderLayer.fillColor = UIColor.clear.cgColor
        borderLayer.lineWidth = 1
        borderLayer.lineDashPattern = [4, 4]
        
        boxView.layer.addSublayer(borderLayer)
    }
    
    func configure(with country: Country) {
        nameRegionLabel.text = "\(country.name), \(country.region)"
        codeLabel.text = country.code
        capitalLabel.text = country.capital
    }
}

// MARK: - Country Detail View Controller
class CountryDetailViewController: UIViewController {
    
    // MARK: - Properties
    private let country: Country
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // MARK: - Initialization
    init(country: Country) {
        self.country = country
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupScrollView()
        setupContentView()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        title = country.name
        view.backgroundColor = .systemBackground
    }
    
    private func setupScrollView() {
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupContentView() {
        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .leading
        
        contentView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
        
        addDetailSection(to: stackView, title: "Name", value: country.name)
        addDetailSection(to: stackView, title: "Region", value: country.region)
        addDetailSection(to: stackView, title: "Code", value: country.code)
        addDetailSection(to: stackView, title: "Capital", value: country.capital)
    }
    
    private func addDetailSection(to stackView: UIStackView, title: String, value: String) {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = UIFont.systemFont(ofSize: 16)
        valueLabel.numberOfLines = 0
        
        let sectionStack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        sectionStack.axis = .vertical
        sectionStack.spacing = 8
        
        stackView.addArrangedSubview(sectionStack)
        
        if title != "Capital" {
            let separator = UIView()
            separator.backgroundColor = .separator
            separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
            
            stackView.addArrangedSubview(separator)
            separator.widthAnchor.constraint(equalTo: stackView.widthAnchor).isActive = true
        }
    }
}

