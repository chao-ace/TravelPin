import SwiftUI
import SwiftData

struct LuggageView: View {
    @Bindable var travel: Travel
    @Environment(\.modelContext) private var modelContext
    
    @State private var newItemName = ""
    @State private var selectedCategory = LuggageCategory.clothes
    
    var body: some View {
        List {
            Section(header: Text("Add to Matrix")) {
                HStack {
                    TextField("New item...", text: $newItemName)
                        .font(TPDesign.bodyFont())
                    
                    Picker("Cat", selection: $selectedCategory) {
                        ForEach(LuggageCategory.allCases, id: \.self) { cat in
                            Image(systemName: cat.icon).tag(cat)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Button(action: addItem) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.tpAccent)
                    }
                    .disabled(newItemName.isEmpty)
                }
            }
            
            ForEach(LuggageCategory.allCases, id: \.self) { category in
                let items = travel.luggageItems.filter { $0.category == category.rawValue }
                if !items.isEmpty {
                    Section(header: Label(category.rawValue, systemImage: category.icon)) {
                        ForEach(items) { item in
                            HStack {
                                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(item.isChecked ? .green : .secondary)
                                    .onTapGesture {
                                        item.isChecked.toggle()
                                    }
                                
                                Text(item.name)
                                    .strikethrough(item.isChecked)
                                    .foregroundStyle(item.isChecked ? .secondary : .primary)
                                
                                Spacer()
                            }
                        }
                        .onDelete { indexSet in
                            deleteItems(at: indexSet, in: items)
                        }
                    }
                }
            }
        }
        .navigationTitle("Packing Matrix")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func addItem() {
        let newItem = LuggageItem(name: newItemName, category: selectedCategory.rawValue)
        newItem.travel = travel
        modelContext.insert(newItem)
        newItemName = ""
    }
    
    private func deleteItems(at offsets: IndexSet, in items: [LuggageItem]) {
        for index in offsets {
            modelContext.delete(items[index])
        }
    }
}
