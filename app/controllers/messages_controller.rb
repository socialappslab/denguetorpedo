# encoding: UTF-8

class MessagesController < ApplicationController
  before_filter :require_login
end
