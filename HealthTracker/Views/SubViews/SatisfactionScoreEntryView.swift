//
//  SatisfactionScoreEntryView.swift
//  HealthTracker/Views
//
//  Created by Arthur Efremenko on 10/26/25.
//

import SwiftUI


/// A slider selector that lets the user choose a daily
/// satisfaction score between 1 and 10.
///
/// 'SatisfactionScoreEntryView' displays ten vertical bars which each represent
/// a possible score value. The user can tap or drag across the bars to update
/// the bound 'satisfactionScore'. The selected score is also displayed.
///
/// This view provides:
///  - a visual color gradient based on the current score,
///  - live updates as the user drags across the bars,
///  - graceful handling when 'satisfactionScore' is 'nil'.
struct SatisfactionScoreEntryView: View {
    @Binding var satisfactionScore: Int?
    
    private let barWidth: CGFloat = UIScreen.main.bounds.size.width / 10 - 16
    private let barHeight: CGFloat = 80
    private let barSpacing: CGFloat = 8
    
    var body: some View {
        HStack(spacing: 20) {
            Spacer()
            ZStack {
                GeometryReader { geometry in
                    HStack(spacing: barSpacing) {
                        ForEach(1...10, id: \.self) { index in
                            Rectangle()
                                .fill(satisfactionScore == nil ? Color.secondary : (index <= satisfactionScore! ? backgroundColor(for: satisfactionScore).opacity(0.8) : Color.secondary))
                                .frame(width: barWidth, height: barHeight)
                                .cornerRadius(4)
                        }
                    }
                    .padding()
                    .background(.primary.opacity(0.1))
                    .cornerRadius(12)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                updateValue(for: value.location, in: geometry)
                            }
                    )
                }
                
                HStack {
                    Spacer()
                    VStack {
                        Spacer()
                        Text(satisfactionScore == nil ? "?" : String(satisfactionScore!))
                            .font(.largeTitle)
                            .foregroundStyle(.black)
                            .fontWeight(.black)
                            .frame(width: 50, height: 50)
                            .background(.white, in: Circle())
                    }
                }
                .padding(10)
            }
            
            Spacer()

        }
        .frame(height: barHeight + 40)
        .sensoryFeedback(.selection, trigger: satisfactionScore)
    }

    /// Updates the bound satisfaction score based on the drag location.
    ///
    /// This method converts the user's horizontal drag position into a bar
    /// index of 1 to 10. The value is clamped to the valid range and assigned
    /// to 'satisfactionScore' if it differs from the current value.
    ///
    /// - Parameters:
    ///   - location: The drag location within the view.
    ///   - geometry: A 'GeometryProxy' describing the layout size so the
    ///               method can correctly compute bar widths and spacing.
    private func updateValue(for location: CGPoint, in geometry: GeometryProxy) {
        let padding: CGFloat = 16
        let adjustedX = location.x - padding
        
        let barUnitWidth = barWidth + barSpacing
        
        let barIndex = Int((adjustedX / barUnitWidth).rounded(.down)) + 1
        
        let newValue = max(1, min(10, barIndex))
        
        if newValue != satisfactionScore {
            satisfactionScore = newValue
        }
    }
    
    /// Maps a satisfaction score to a smooth red, yellow, green color gradient.
    ///
    /// Scores near 1 appear red, scores near 5 appear yellow, and scores near
    /// 10 appear green.
    ///
    /// - Parameters:
    ///   - score: The score value from 1 to 10 used to determine the color.
    ///
    /// - Returns:
    ///   - 'Color': representing the color for the given score, clear if nil.
    private func backgroundColor(for score: Int?) -> Color {
        guard let score = score else { return .clear }
        let t = Double(score) / 10.0
        if t <= 0.5 {
            let p = t / 0.5
            return Color(red: 1, green: p, blue: 0)
        } else {
            let p = (t - 0.5) / 0.5
            return Color(red: 1 - p, green: 1, blue: 0)
        }
    }
}

#Preview {
    @Previewable @State var satisfactionScore: Int? = nil
    
    SatisfactionScoreEntryView(satisfactionScore: $satisfactionScore)
}
