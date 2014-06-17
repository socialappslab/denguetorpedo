module NeighborhoodsHelper
  include ActionView::Helpers::NumberHelper

  #----------------------------------------------------------------------------

  def pretty_print_points(points)
    number_to_human(points, precision: 3, :units => {:thousand => "K", :million => "M", :billion => "B"}, :separator => ".", :format => "%n%u")
  end

  #----------------------------------------------------------------------------
end
