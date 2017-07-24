json.header do
  json.time      I18n.t('views.statistics.chart.time')
  json.positive  I18n.t('views.statistics.chart.percent_of_positive_sites')
  json.potential I18n.t('views.statistics.chart.percent_of_potential_sites')
  json.negative  I18n.t('views.statistics.chart.percent_of_negative_sites')
end
json.timeseries  @statistics
json.odds_ratios @odds_ratios
