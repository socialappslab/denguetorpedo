# -*- encoding : utf-8 -*-

class Dashboard::SyncController < Dashboard::BaseController
  #----------------------------------------------------------------------------
  # GET /sync/graphs

  def index
    authorize :dashboard, :index?

    @locations = Location.where(:source => "mobile").limit(100).order("created_at DESC").includes(:visits)
    @visits    = Visit.where(:source => "mobile").order("visited_at DESC").includes(:location)
    @reports   = Report.where(:source => "mobile").order("created_at DESC")

    # @breadcrumbs << {:name => I18n.t("views.dashboard.navigation.sync"), :path => request.path}
  end
end
