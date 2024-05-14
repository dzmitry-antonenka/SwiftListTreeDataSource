//
//  SwiftUIListWithSearch.swift
//  TreeView
//
//  Created by Dzmitry Antonenka on 5/14/24.
//

import SwiftUI
import SwiftListTreeDataSource

class SwiftUIListWithSearchHosting: UIHostingController<SwiftUIListWithSearch> {
    init() {
        super.init(rootView: SwiftUIListWithSearch())
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        super.init(rootView: SwiftUIListWithSearch())
    }
}

struct SwiftUIListWithSearch: View {
    @StateObject private var store = SwiftListTreeDataStore()
    @State private var searchText = ""

    var body: some View {
        NavigationView {
            List {
                ForEach(store.items) { element in
                    Button(action: {
                        withAnimation {
                            store.toggleExpand(item: element)
                        }
                    }) {
                        HStack(spacing: 0) {
                            Spacer().frame(width: spaceForLevel(element.level))

                            Text(attributedTitle(element.value.title))
                    
                            Spacer(minLength: 4)

                            if !element.subitems.isEmpty {
                                Image(systemName: "chevron.right")
                                    .font(Font.system(.footnote)
                                        .weight(.semibold))
                                    .foregroundColor(.blue)
                                    .rotationEffect(element.isExpanded ? .degrees(90) : .zero)
                                    .animation(.default)
                            }
                        }
                    }
                    .buttonStyle(.automatic)
                }
            }
            .listStyle(.plain)
        }
        .searchable(text: $searchText)
        .onAppear(perform: runSearch)
        .onSubmit(of: .search, runSearch)
        .onChange(of: searchText) { _ in
            runSearch()
        }
    }

    private func spaceForLevel(_ level: Int) -> CGFloat {
        11 + CGFloat(10 * level)
    }
    
    private func attributedTitle(_ title: String) -> AttributedString {
        let mattrString = NSMutableAttributedString(string: title, attributes: [ .foregroundColor: UIColor.black ])
        if !searchText.isEmpty {
            let range = (title.lowercased() as NSString).range(of: searchText.lowercased())
            mattrString.addAttributes([
                .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
            ], range: range)
        }
        return AttributedString(mattrString)
    }

    private func runSearch() {
        store.searchBar(textDidChange: searchText)
    }
}

extension NavigationLink where Label == AnyView, Destination == EmptyView {

   /// Useful in cases where a `NavigationLink` is needed but there should not be
   /// a destination. e.g. for programmatic navigation.
   static var empty: NavigationLink {
       self.init(destination: EmptyView(), label: {
           AnyView(Image(systemName: "chevron.right").font(Font.system(.footnote).weight(.semibold)))
       })
   }
}
