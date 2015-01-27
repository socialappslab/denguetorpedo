$(function () {
  $('.datetimepicker').datetimepicker({
    language: "#{I18n.locale.to_s}",
    pickTime: true,
    useCurrent: true,
    icons: {
      time: 'fa fa-time',
      date: 'fa fa-calendar',
      up: 'fa fa-chevron-up',
      down: 'fa fa-chevron-down',
      previous: 'fa fa-chevron-left',
      next: 'fa fa-chevron-right',
      today: 'fa fa-screenshot',
      clear: 'fa fa-trash'
    }
  });
});
