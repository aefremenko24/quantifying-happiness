//
//  SurveyView.swift
//  HealthTracker
//
//  Created by Arthur Efremenko on 10/26/25.
//

import SwiftUI

struct SurveyView: View {
    var body: some View {
        VStack {
            HStack{
                Text("\(Date().formatted(Date.FormatStyle().weekday(.wide).day(.twoDigits).month(.abbreviated)))")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(20)
                Spacer()
            }
            
            SatisfactionScoreEntryView()
                .padding(10)
            
            HealthDataView()
            
            Spacer()
        }
    }
}

#Preview {
    SurveyView()
}
