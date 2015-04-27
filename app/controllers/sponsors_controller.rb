# -*- encoding : utf-8 -*-
class SponsorsController < ApplicationController
	def show
		@sponsor = User.find(params[:id])
		raise ActionController::RoutingError.new('Not Found') if @sponsor.role != User::Types::SPONSOR
		@prizes = @sponsor.prizes
	end

	def new
		@user = User.new
	end
end
