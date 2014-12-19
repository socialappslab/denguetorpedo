$(function () {
  $('.datetimepicker').datetimepicker({
    language: "#{I18n.locale.to_s}",
    pickTime: false,
    useCurrent: true
  });
});
