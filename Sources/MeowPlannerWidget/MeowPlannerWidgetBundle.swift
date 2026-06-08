#if MEOWPLANNER_WIDGET_EXTENSION
import SwiftUI
import WidgetKit

@main
struct MeowPlannerWidgetBundle: WidgetBundle {
    var body: some Widget {
        MeowPlannerTodayWidget()
    }
}
#endif
