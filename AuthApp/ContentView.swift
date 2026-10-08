//
//  ContentView.swift
//  AuthenticationSwiftUI
//
//  Created by Muhammad Mamun on 19/11/23.
//


import SwiftUI



struct ContentView: View {
    @AppStorage("isLoggedIn") var isLoggedIn = false
    @State private var isSplashShowing:Bool = false
    
    var body: some View {
        
        VStack {
            if !isSplashShowing{
                SplashView()
            }
            else{
                if isLoggedIn{
                    DashboardProductView()
                }else{
                    LoginView(isLoggedIn: $isLoggedIn)
                }
            }
        }
        .onAppear{
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0){
                isSplashShowing = true
            }
        }
    }
    
}


#Preview {
    ContentView()
}







//import SwiftUI
//
//struct CellView: View {
//    let item: Int // Modify this based on the type of your data
//    
//    var body: some View {
//        // Customize the cell design based on your requirements
//        Text("\(item)")
//            .frame(width: 220, height: 180)
//            .background(Color.blue)
//            .cornerRadius(8)
//            .foregroundColor(.white)
//    }
//}
//
//struct ContentView: View {
//    let data = Array(1...26) // Replace this with your actual data
//
//    var body: some View {
//        ScrollView {
//            LazyVGrid(columns: [GridItem(.flexible())], spacing: 16) {
//                ForEach(0..<data.count / 5, id: \.self) { rowIndex in
//                    VStack(alignment: .leading, spacing: 0) {
//                        Text("Label\(rowIndex + 1)")
//                            .font(.largeTitle)
//                            .padding(.leading, 0)
//                    }
//                    .frame(maxWidth: .infinity, alignment: .leading) // Ensure the label takes the full width
//
//                    ScrollView(.horizontal){
//                        HStack(spacing: 16) {
//                            ForEach(0..<5, id: \.self) { columnIndex in
//                                let index = rowIndex * 5 + columnIndex
//                                if index < data.count {
//                                    CellView(item: data[index])
//                                }
//                            }
//                        }
//                    }
//                }
//            }
//            .padding(20)
//        }
//    }
//}


//struct ContentView: View {
//    @State private var searchText = ""
//    @State private var isSearching = false
//
//    let data = ["Apple", "Banana", "Cherry", "Date", "Fig", "Grape", "Kiwi", "Lemon", "Mango", "Orange", "Peach", "Pear", "Pineapple", "Plum", "Strawberry", "Watermelon"]
//
//    var filteredData: [String] {
//        if searchText.isEmpty {
//            return data
//        } else {
//            return data.filter { $0.lowercased().contains(searchText.lowercased()) }
//        }
//    }
//
//    var body: some View {
//        NavigationView {
//            List {
//                SearchBar(searchText: $searchText, isSearching: $isSearching)
//
//                ForEach(filteredData, id: \.self) { item in
//                    Text(item)
//                }
//            }
//            .navigationTitle("Fruits")
//        }
//    }
//}
//
//struct SearchBar: View {
//    @Binding var searchText: String
//    @Binding var isSearching: Bool
//
//    var body: some View {
//        HStack {
//            TextField("Search...", text: $searchText)
//                .padding(.leading, 24)
//                .onChange(of: searchText) { newValue in
//                    isSearching = true
//                }
//
//            Button {
//                searchText = ""
//                isSearching = false
//            } label: {
//                Image(systemName: "xmark.circle.fill")
//                    .padding(.horizontal)
//            }
//            .opacity(isSearching ? 1 : 0)
//            .animation(.default)
//        }
//        .padding(.vertical, 10)
//    }
//}



//struct ContentView: View {
//    @State private var searchText = ""
//    
//    let fruits = ["Apple", "Banana", "Cherry", "Date", "Fig", "Grape", "Kiwi", "Lemon", "Mango", "Orange", "Peach", "Pear", "Pineapple", "Plum", "Strawberry", "Watermelon"]
//
//    var filteredFruits: [String] {
//        searchText.isEmpty ? fruits : fruits.filter { $0.lowercased().contains(searchText.lowercased()) }
//    }
//
//    var body: some View {
//        NavigationView {
//            List {
//                ForEach(filteredFruits, id: \.self) { fruit in
//                    Text(fruit)
//                }
//            }
//            .navigationTitle("Fruits")
//            .searchable(text: $searchText, prompt: "SearchItems")
//        }
//    }
//}
//
//struct SearchBar: View {
//    @Binding var text: String
//
//    var body: some View {
//        HStack {
//            TextField("Search", text: $text)
//                .padding(10)
//                .background(Color(.systemGray5))
//                .cornerRadius(8)
//                .padding(.horizontal, 5)
//        }
//        .padding(.vertical, 8)
//    }
//}
