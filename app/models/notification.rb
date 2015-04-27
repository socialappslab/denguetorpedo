# -*- encoding : utf-8 -*-
class Notification < ActiveRecord::Base
  attr_accessible :board, :phone, :text
end
