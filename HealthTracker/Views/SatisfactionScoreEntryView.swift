//
//  SatisfactionScoreEntryView.swift
//  HealthTracker/Views
//
//  Created by Arthur Efremenko on 10/26/25.
//

import SwiftUI

struct SatisfactionScoreEntryView: View {
    @Binding var satisfactionScore: Float
    @State private var isEditing = false

    var body: some View {
        VStack {
            Text("Today's satisfaction score")
            Slider(
                value: $satisfactionScore,
                in: 0...10,
                step: 1,
                onEditingChanged: { isEditing = $0 }
            ) {
                Text("Satisfaction score")
            } minimumValueLabel: {
                Text("0")
            } maximumValueLabel: {
                Text("10")
            }
            Text("\(Int(satisfactionScore))")
                .foregroundStyle(isEditing ? .red : .blue)
                .font(.title)
                .fontWeight(.bold)
        }
    }
}

#Preview {
    SatisfactionScoreEntryView()
}
