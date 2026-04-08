import SwiftUI
import SwiftData

struct PhotoGalleryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let travel: Travel
    
    @State private var selectedPhoto: TravelPhoto?
    @State private var isSelectMode = false
    @State private var selectedPhotos: Set<UUID> = []
    @State private var isShowingFullscreen = false
    
    // Grid columns configuration
    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]
    
    var allPhotos: [TravelPhoto] {
        travel.spots
            .flatMap { $0.photos }
            .sorted { $0.createdAt > $1.createdAt }
    }
    
    var body: some View {
        ZStack {
            TPDesign.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerView
                
                if allPhotos.isEmpty {
                    emptyStateView
                } else {
                    photoGrid
                }
            }
        }
        .navigationBarHidden(true)
        .overlay {
            if isShowingFullscreen, let photo = selectedPhoto {
                PhotoFullscreenViewer(
                    photos: allPhotos,
                    currentIndex: allPhotos.firstIndex(where: { $0.id == photo.id }) ?? 0,
                    isPresented: $isShowingFullscreen
                )
                .transition(.opacity)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(TPDesign.obsidian)
                        .padding(8)
                        .background(Circle().fill(TPDesign.alabaster))
                }
                
                Spacer()
                
                Text(locKey: "detail.archive.title")
                    .font(TPDesign.editorialSerif(20))
                    .foregroundStyle(TPDesign.obsidian)
                
                Spacer()
                
                Button {
                    withAnimation(.spring()) {
                        isSelectMode.toggle()
                        selectedPhotos.removeAll()
                    }
                } label: {
                    Text(isSelectMode ? "common.cancel".localized : "common.edit".localized)
                        .font(TPDesign.bodyFont(14, weight: .bold))
                        .foregroundStyle(isSelectMode ? .red : Color.tpAccent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(isSelectMode ? Color.red.opacity(0.1) : Color.tpAccent.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 15)
            
            if isSelectMode {
                HStack {
                    Text("selected.count".localized + " \(selectedPhotos.count)")
                        .font(TPDesign.captionFont())
                        .foregroundStyle(TPDesign.textSecondary)
                    
                    Spacer()
                    
                    Button {
                        deleteSelectedPhotos()
                    } label: {
                    Label("common.delete".localized, systemImage: "trash")
                            .font(TPDesign.captionFont())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedPhotos.isEmpty ? Color.gray : Color.red)
                            .clipShape(Capsule())
                    }
                    .disabled(selectedPhotos.isEmpty)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(TPDesign.background.opacity(0.95))
    }
    
    private var photoGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(allPhotos) { photo in
                    PhotoGridCell(
                        photo: photo,
                        isSelectMode: isSelectMode,
                        isSelected: selectedPhotos.contains(photo.id)
                    )
                    .onTapGesture {
                        if isSelectMode {
                            if selectedPhotos.contains(photo.id) {
                                selectedPhotos.remove(photo.id)
                            } else {
                                selectedPhotos.insert(photo.id)
                            }
                            TPHaptic.selection()
                        } else {
                            selectedPhoto = photo
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                isShowingFullscreen = true
                            }
                        }
                    }
                }
            }
            .padding(.top, 2)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundStyle(TPDesign.textTertiary)
            Text(locKey: "detail.archive.empty")
                .font(TPDesign.bodyFont())
                .foregroundStyle(TPDesign.textSecondary)
            Spacer()
        }
    }
    
    // MARK: - Actions
    
    private func deleteSelectedPhotos() {
        TPHaptic.notification(.warning)
        for photoId in selectedPhotos {
            if let photo = allPhotos.first(where: { $0.id == photoId }) {
                modelContext.delete(photo)
            }
        }
        try? modelContext.save()
        isSelectMode = false
        selectedPhotos.removeAll()
    }
}

struct PhotoGridCell: View {
    let photo: TravelPhoto
    let isSelectMode: Bool
    let isSelected: Bool
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let data = photo.data, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fit)
                    .clipped()
            } else {
                Rectangle()
                    .fill(TPDesign.alabaster)
                    .aspectRatio(1, contentMode: .fit)
            }
            
            if isSelectMode {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.tpAccent : .black.opacity(0.2))
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .padding(8)
            }
        }
    }
}

// MARK: - Fullscreen Viewer

struct PhotoFullscreenViewer: View {
    let photos: [TravelPhoto]
    @State var currentIndex: Int
    @Binding var isPresented: Bool
    
    @State private var offset: CGSize = .zero
    @State private var scale: CGFloat = 1.0
    @GestureState private var magnifyScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            TabView(selection: $currentIndex) {
                ForEach(0..<photos.count, id: \.self) { index in
                    if let data = photos[index].data, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .tag(index)
                            .scaleEffect(currentIndex == index ? scale * magnifyScale : 1.0)
                            .offset(currentIndex == index ? offset : .zero)
                            .gesture(
                                MagnificationGesture()
                                    .updating($magnifyScale) { value, state, _ in
                                        state = value
                                    }
                                    .onEnded { value in
                                        scale *= value
                                        if scale < 1.0 { scale = 1.0 }
                                        if scale > 4.0 { scale = 4.0 }
                                    }
                            )
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Overlays
            VStack {
                HStack {
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(12)
                            .background(.black.opacity(0.4))
                            .clipShape(Circle())
                    }
                    .padding()
                    
                    Spacer()
                    
                    if photos.indices.contains(currentIndex), let spot = photos[currentIndex].spot {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(spot.name)
                                .font(TPDesign.editorialSerif(18))
                                .foregroundStyle(.white)
                            Text(photos[currentIndex].createdAt.formatted(date: .abbreviated, time: .omitted))
                                .font(TPDesign.captionFont())
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        .padding()
                    }
                }
                
                Spacer()
                
                Text("\(currentIndex + 1) / \(photos.count)")
                    .font(TPDesign.captionFont())
                    .foregroundStyle(.white)
                    .padding(.bottom, 20)
            }
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    if scale == 1.0 {
                        offset = value.translation
                    }
                }
                .onEnded { value in
                    if scale == 1.0 {
                        if abs(value.translation.height) > 100 {
                            isPresented = false
                        } else {
                            withAnimation(.spring()) {
                                offset = .zero
                            }
                        }
                    }
                }
        )
    }
}
