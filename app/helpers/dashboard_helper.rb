# -*- encoding : utf-8 -*-
module DashboardHelper

  def dashboard_navigation_menu
    [
      ["CSV", dashboard_csv_index_path, "fa-file-o"],
      [I18n.t("views.dashboard.navigation.locations"), dashboard_locations_path, "fa-search"],
      ["Visita Datos", dashboard_visits_path, "fa-table"],
      [I18n.t("views.dashboard.navigation.graphs"), dashboard_graphs_path, "fa-bar-chart"],
      [I18n.t("views.dashboard.navigation.heatmap"), heatmap_dashboard_graphs_path, "fa-globe"]
    ]

  end

end
