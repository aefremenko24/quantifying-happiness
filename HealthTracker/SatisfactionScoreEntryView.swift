//
//  SatisfactionScoreEntryView.swift
//  HealthTracker
//
//  Created by Arthur Efremenko on 10/26/25.
//

import SwiftUI

struct SatisfactionScoreEntryView: View {
    @State private var satisfactionScore: Float = 5.0
    @State private var isEditing = false
    
    var body: some View {
        VStack {
            Text("Today's satisfaction score")
            
            Slider(
                value: $satisfactionScore,
                in: 0...10,
                step: 1
            ) {
                Text("Satisfaction score")
            } minimumValueLabel: {
                Text("0")
            } maximumValueLabel: {
                Text("10")
            } onEditingChanged: { editing in
                isEditing = editing
            }
            Text("\(Int(satisfactionScore))")
                .foregroundColor(isEditing ? .red : .blue)
                .font(.title)
                .fontWeight(.bold)
        }
    }
}

#Preview {
    SatisfactionScoreEntryView()
}
