//
//  SatisfactionScoreEntryView.swift
//  HealthTracker/Views
//
//  Created by Arthur Efremenko on 10/26/25.
//

import SwiftUI

struct SatisfactionScoreEntryView: View {
    @Binding var satisfactionScore: Int
    
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
                                .fill(index <= satisfactionScore ? backgroundColor(for: satisfactionScore).opacity(0.8) : Color.secondary)
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
                        Text(String(satisfactionScore))
                            .font(.largeTitle)
                            .foregroundStyle(.primary)
                            .fontWeight(.black)
                            .frame(width: 50, height: 50)
                            .background(.white, in: Circle())
                    }
                }
                .padding(10)
            }
            
            Spacer()

        }
        .frame(width: .infinity, height: barHeight + 40)
    }
    
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
    
    // Helper function to map user satisfaction score to a color where closer to 0 is red, yellow is around 5, and green is 10
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
    @Previewable @State var satisfactionScore = 5
    
    SatisfactionScoreEntryView(satisfactionScore: $satisfactionScore)
}
