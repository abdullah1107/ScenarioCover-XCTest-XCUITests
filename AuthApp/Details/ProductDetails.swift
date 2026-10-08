//
//  ProductDetails.swift
//  AuthUI
//
//  Created by Muhammad Mamun on 11/12/23.
//

import SwiftUI

struct ProductDetails: View {

    @StateObject private var viewModel: ProductDetailsViewModel

    init(product: Product) {
        _viewModel = StateObject(wrappedValue: ProductDetailsViewModel(product: product))
    }

    init(viewModel: ProductDetailsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if case .failed(let message) = viewModel.state {
                    ErrorBanner(message: message) { viewModel.load() }
                }

                ProductImageGallery(urls: viewModel.imageURLs, selection: $viewModel.selectedImageIndex)

                header
                priceBlock

                DetailSection(title: "Description") {
                    Text(viewModel.detail.description)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("productDescription")
                }

                if !viewModel.detail.tags.isEmpty {
                    TagsRow(tags: viewModel.detail.tags)
                }

                if !viewModel.infoRows.isEmpty {
                    DetailSection(title: "Details") {
                        VStack(spacing: 0) {
                            ForEach(Array(viewModel.infoRows.enumerated()), id: \.offset) { index, row in
                                InfoRow(label: row.label, value: row.value)
                                if index < viewModel.infoRows.count - 1 { Divider() }
                            }
                        }
                    }
                }

                if !viewModel.detail.reviews.isEmpty {
                    DetailSection(title: "Reviews (\(viewModel.detail.reviews.count))") {
                        VStack(spacing: 12) {
                            ForEach(viewModel.detail.reviews) { ReviewCard(review: $0) }
                        }
                    }
                }
            }
            .padding()
        }
        .overlay {
            if viewModel.state == .loading { LoadingBadge() }
        }
        .navigationTitle("Product")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.load() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(viewModel.detail.title)
                .font(.title.bold())
                .accessibilityIdentifier("productDetailsIdentifier")
            if let brand = viewModel.detail.brand, !brand.isEmpty {
                Text(brand).font(.subheadline).foregroundColor(.secondary)
            }
            HStack(spacing: 6) {
                StarRating(rating: viewModel.detail.rating)
                Text(viewModel.ratingText).font(.subheadline.weight(.semibold))
            }
        }
    }

    private var priceBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(viewModel.priceText)
                    .font(.largeTitle.bold())
                    .foregroundColor(.green)
                    .accessibilityIdentifier("productPrice")
                if viewModel.hasDiscount {
                    Text(viewModel.originalPriceText)
                        .strikethrough()
                        .foregroundColor(.secondary)
                    Text(viewModel.discountText)
                        .font(.caption.bold())
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.red.opacity(0.15))
                        .foregroundColor(.red)
                        .cornerRadius(6)
                }
            }
            Label(viewModel.availabilityText,
                  systemImage: viewModel.detail.stock > 0 ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.subheadline)
                .foregroundColor(viewModel.detail.stock > 0 ? .green : .red)
        }
    }
}

// MARK: - Subviews

private struct ProductImageGallery: View {
    let urls: [URL]
    @Binding var selection: Int

    var body: some View {
        VStack(spacing: 10) {
            if urls.isEmpty {
                placeholder.frame(height: 300)
            } else {
                TabView(selection: $selection) {
                    ForEach(Array(urls.enumerated()), id: \.offset) { index, url in
                        RemoteImage(url: url).padding().tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: urls.count > 1 ? .always : .never))
                .frame(height: 300)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                .accessibilityIdentifier("productImageCarousel")

                if urls.count > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(urls.enumerated()), id: \.offset) { index, url in
                                RemoteImage(url: url)
                                    .frame(width: 56, height: 56)
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(8)
                                    .overlay(RoundedRectangle(cornerRadius: 8)
                                        .stroke(index == selection ? Color.green : Color.clear, lineWidth: 2))
                                    .onTapGesture { withAnimation { selection = index } }
                            }
                        }
                    }
                }
            }
        }
    }

    private var placeholder: some View {
        ZStack {
            Color(.secondarySystemBackground)
            Image(systemName: "photo").font(.largeTitle).foregroundColor(.secondary)
        }
        .cornerRadius(16)
    }
}

private struct RemoteImage: View {
    let url: URL

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFit()
            case .failure:
                Image(systemName: "photo").font(.title).foregroundColor(.secondary)
            default:
                ProgressView()
            }
        }
    }
}

private struct StarRating: View {
    let rating: Double

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: symbol(for: star)).foregroundColor(.yellow)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rating \(String(format: "%.1f", rating)) out of 5")
    }

    private func symbol(for star: Int) -> String {
        if rating >= Double(star) { return "star.fill" }
        if rating >= Double(star) - 0.5 { return "star.leadinghalf.filled" }
        return "star"
    }
}

private struct DetailSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline)
            content
        }
    }
}

private struct TagsRow: View {
    let tags: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(tags, id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.caption)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                }
            }
        }
    }
}

private struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label).foregroundColor(.secondary)
            Spacer(minLength: 16)
            Text(value).multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
        .padding(.vertical, 8)
    }
}

private struct ReviewCard: View {
    let review: ProductDetail.Review

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(review.reviewerName).font(.subheadline.weight(.semibold))
                Spacer()
                StarRating(rating: Double(review.rating))
            }
            Text(review.comment).font(.subheadline)
            Text(Self.formatted(review.date)).font(.caption).foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private static func formatted(_ iso: String) -> String {
        let parser = ISO8601DateFormatter()
        parser.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let plain = ISO8601DateFormatter()
        guard let date = parser.date(from: iso) ?? plain.date(from: iso) else { return iso }
        return date.formatted(date: .abbreviated, time: .omitted)
    }
}

private struct ErrorBanner: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(message).font(.footnote)
            Spacer()
            Button("Retry", action: retry).font(.footnote.bold())
        }
        .padding()
        .background(Color.orange.opacity(0.2))
        .cornerRadius(10)
        .accessibilityIdentifier("productDetailsError")
    }
}

private struct LoadingBadge: View {
    var body: some View {
        VStack {
            ProgressView()
                .padding(10)
                .background(.ultraThinMaterial)
                .cornerRadius(10)
            Spacer()
        }
        .padding(.top, 8)
    }
}

#Preview {
    NavigationView {
        ProductDetails(product: Product(id: 1, title: "Essence Mascara Lash Princess",
                                        description: "A popular mascara known for its volumizing and lengthening effects.",
                                        price: 9.99, discountPercentage: 7.17, rating: 4.94, stock: 5,
                                        brand: "Essence", category: "beauty"))
    }
}
