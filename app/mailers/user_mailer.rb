# -*- encoding : utf-8 -*-
class UserMailer < ActionMailer::Base
  default from: "reportdengue@gmail.com"

  #----------------------------------------------------------------------------

  def password_reset(user)
    @user = user
    mail to: user.email, subject: I18n.t("views.user_mailer.password_reset.subject")
  end

  #----------------------------------------------------------------------------

  def group_buy_in_invitation(user, group)
    @user = user
    @group = group
    mail to: user.email, subject: "Group Buy In Invitation!!!"
  end

  #----------------------------------------------------------------------------

  def decline_invitation(user, buyIn)
    @user = user
    @buyIn = buyIn
    mail to: user.email, subject: "Friend has declined your Group By In Invitation"
  end

  #----------------------------------------------------------------------------

  def accept_invitation(user, buyIn)
    @user = user
    @buyIn = buyIn
    mail to: user.email, subject: "Friend has accepted your Group By In Invitation"
  end

  #----------------------------------------------------------------------------

  def item_bought(user, group)
    @user = user
    @group = group
    mail to: user.email, subject: "Group Buy In Completed!!!"
  end

  #----------------------------------------------------------------------------

  def send_contact(feedback)
    body = "Someone filled out the feedback form.\n\nEmail = #{feedback.email}\n\nName = #{feedback.name}\n\nMessage = #{feedback.message}"
    mail(to: "dmitriskj@gmail.com", :from => "support@denguechat.org", subject: "Interest in using DengueChat", :body => body)
    mail(to: "jholston@berkeley.edu", :from => "support@denguechat.org", subject: "Interest in using DengueChat", :body => body)
  end

  #----------------------------------------------------------------------------

end
