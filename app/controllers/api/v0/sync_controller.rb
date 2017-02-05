
class API::V0::SyncController < API::V0::BaseController
  skip_before_filter :authenticate_user_via_device_token
  before_action :authenticate_user_via_jwt
  before_action :current_user_via_jwt

  #-------------------------------------------------------------------------------------------------
  # PUT /api/v0/sync/post

  # Two keys come in:
  # 1. changes which is the Changes Feed in PouchDB (https://pouchdb.com/guides/changes.html)
  # 2. sync_status which contains last_synced_at timestamp, if any.
  def post
    # Iterate over each change to the measurement, storing it in
    # TODO: How many changes will there be???
    changes_params["results"].each do |result|
      p_params = result["doc"].with_indifferent_access
      pid      = p_params[:id]

      # If the post is present, then we can only really update a like or comment on it.
      if pid.present? && @post = Post.find_by_id(pid)

        if p_params[:liked].to_s.present?
          existing_like = @post.likes.find {|like| like.user_id == @current_user.id }
          if existing_like.present? && p_params[:liked].to_s == "false"
            existing_like.destroy
          elsif existing_like.blank? && p_params[:liked].to_s == "true"
            Like.create(:user_id => @current_user.id, :likeable_id => @post.id, :likeable_type => Post.name)
            Analytics.track( :user_id => @current_user.id, :event => "Liked a post", :properties => {:post => @post.id}) if Rails.env.production?
          end
        end

      else
        @post                 = Post.new(p_params)
        @post.user_id         = @current_user.id
        @post.neighborhood_id = Neighborhood.find(p_params[:neighborhood_id]).id

        base64_image = p_params[:photo]
        if base64_image.present?
          filename             = @current_user.display_name.underscore + "_post_photo.jpg"
          paperclip_image      = prepare_base64_image_for_paperclip(base64_image, filename)
          @post.photo = paperclip_image
        end

        # Iterate over the content, identifying mentions by @, and then wrapping
        # the valid usernames with <a> HTML tag.
        mentioned_users = []
        @post.content.scan(/@\w*/).each do |mention|
          u = User.find_by_username( mention.gsub("@","") )

          if u.present?
            @post.content.gsub!(mention, "<a href='#{user_path(u)}'>#{mention}</a>")
            mentioned_users << u
          end
        end

        if @post.save
          @post.update_column(:created_at, Time.parse(p_params[:created_at]) )
          # Now that we know the post is valid, let's go ahead and notify the mentioned
          # users.
          mentioned_users.each do |u|
            un = UserNotification.create(:user_id => u.id, :notification_id => @post.id, :notification_type => "Post", :notified_at => Time.zone.now, :medium => UserNotification::Mediums::WEB)
          end
        end
      end
    end

    # At this point, all measurements have saved. Let's update the column.
    @last_seq       = changes_params[:last_seq]
    @last_synced_at = Time.now.utc
    @post.update_columns({:last_synced_at => @last_synced_at, :last_sync_seq => @last_seq})
  end


  #-------------------------------------------------------------------------------------------------
  # PUT /api/v0/sync/measurement?event_id=...

  # Two keys come in:
  # 1. changes which is the Changes Feed in PouchDB (https://pouchdb.com/guides/changes.html)
  # 2. sync_status which contains last_synced_at timestamp, if any.
  def location
    changes_params["results"].each do |result|
      p_params = result["doc"].with_indifferent_access
      id       = p_params[:id]

      # If the post is present, then we can only really update a like or comment on it.
      if id.present? && @location = Location.find_by_id(id)
        @location.questions = p_params[:questions] if p_params[:questions].present?
        @location.update_attributes(p_params)
      else
        @location = Location.new(p_params)
        @location.source = "mobile" # Right now, this API endpoint is only used by our mobile endpoint.
        @location.save
      end
    end

    # At this point, all measurements have saved. Let's update the column.
    @last_seq       = changes_params[:last_seq]
    @last_synced_at = Time.now.utc
    @location.update_columns({:last_synced_at => @last_synced_at, :last_sync_seq => @last_seq})
  end

  #-------------------------------------------------------------------------------------------------
  # PUT /api/v0/sync/visit?event_id=...

  # Two keys come in:
  # 1. changes which is the Changes Feed in PouchDB (https://pouchdb.com/guides/changes.html)
  # 2. sync_status which contains last_synced_at timestamp, if any.
  def visit
    changes_params["results"].each do |result|
      p_params = result["doc"].with_indifferent_access
      id       = p_params[:id]

      # If the post is present, then we can only really update a like or comment on it.
      if id.present? && @visit = Visit.find_by_id(id)
        t = Time.zone.parse(p_params[:visited_at])
        @visit.update_column(:visited_at, t)
      else
        location = Location.find_by_id(p_params[:location_id])
        if location.blank?
          raise API::V0::Error.new("We couldn't find an associated location!", 422) and return
        end

        t = Time.zone.parse(p_params[:visited_at])
        @visit = location.visits.where("DATE(visited_at) = ?", t.strftime("%Y-%m-%d")).first
        if @visit.blank?
          @visit = Visit.new(:location_id => location.id)
          @visit.source = "mobile"
        end

        @visit.visited_at = t
        @visit.save!
      end
    end

    # At this point, all measurements have saved. Let's update the column.
    @last_seq       = changes_params[:last_seq]
    @last_synced_at = Time.now.utc
    @visit.update_columns({:last_synced_at => @last_synced_at, :last_sync_seq => @last_seq})
  end

  #-------------------------------------------------------------------------------------------------
  # PUT /api/v0/sync/inspection

  # Two keys come in:
  # 1. changes which is the Changes Feed in PouchDB (https://pouchdb.com/guides/changes.html)
  # 2. sync_status which contains last_synced_at timestamp, if any.
  def inspection
    changes_params["results"].each do |result|
      p_params = result["doc"].with_indifferent_access
      id       = p_params[:id]


      breeding_site      = p_params[:report].delete(:breeding_site)
      elimination_method = p_params[:report].delete(:elimination_method)

      if id.present? && @inspection = Inspection.find_by_id(id)
        @report = @inspection.report
        @report.breeding_site_id = breeding_site[:id]

        if p_params[:report][:before_photo].present? && p_params[:report][:before_photo].exclude?("base64")
          p_params[:report].delete(:before_photo)
        end
        if p_params[:report][:after_photo].present? && p_params[:report][:after_photo].exclude?("base64")
          p_params[:report].delete(:after_photo)
        end

        @report.attributes = p_params[:report]
        @report.save(:validate => false)

        if p_params[:report][:eliminated_at].present?
          t = Time.zone.parse(p_params[:report][:eliminated_at])
          @report.eliminated_at         = t
          @report.elimination_method_id = elimination_method[:id]


          # Create the elimination inspection.
          ins = Inspection.new(:visit_id => @inspection.visit_id, :report_id => @inspection.report_id)
          ins.source              = "mobile"
          ins.identification_type = Inspection::Types::NEGATIVE
          ins.position            = @inspection.position + 1
          ins.save
        end
      else
        # TODO: Need to create report.
        @report = Report.new(p_params[:report])
        @report.source = "mobile"
        @report.breeding_site_id = breeding_site[:id]
        # r.report             = p_params[:report][:report]
        # r.field_identifier   = p_params[:report][:field_identifier]
        # r.breeding_site_id   = p_params[:report][:breeding_site][:id]
        # r.protected          = p_params[:report][:protected]
        # r.chemically_treated = p_params[:report][:chemical]
        # r.larvae             = p_params[:report][:larvae]
        # r.pupae              = p_params[:report][:pupae]
        @report.last_synced_at = @last
        @report.save(:validate => false)

        # Create the corresponding inspection.
        @inspection = Inspection.new(:report_id => @report.id, :visit_id => p_params[:visit_id])
        @inspection.identification_type = @report.original_status
        @inspection.source = "mobile" # Right now, this API endpoint is only used by our mobile endpoint.
        @inspection.save
      end
    end

    # At this point, all measurements have saved. Let's update the column.
    @last_seq       = changes_params[:last_seq]
    @last_synced_at = Time.now.utc
    @inspection.update_columns({:last_synced_at => @last_synced_at, :last_sync_seq => @last_seq})
    @report.update_columns({:last_synced_at => @last_synced_at, :last_sync_seq => @last_seq}) if @report.present?
  end


  #-------------------------------------------------------------------------------------------------

  private

  def changes_params
    params.require(:changes)
  end

  def sync_status_params
    params.require(:sync_status)
  end
end
