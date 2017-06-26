
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
        if @post.content.present?
          @post.content.scan(/@\w*/).each do |mention|
            u = User.find_by_username( mention.gsub("@","") )

            if u.present?
              @post.content.gsub!(mention, "<a href='#{user_path(u)}'>#{mention}</a>")
              mentioned_users << u
            end
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

      # If the location's id exists and the location is found, then let's update the
      # location.
      if id.present? && @location = Location.find_by_id(id)
        @location.questions = p_params[:questions] if p_params[:questions].present?
        @location.update_attributes(p_params)
      else
        # At this point, the location's ID does not exist which means this is a new location.
        # Let's store it, and the pouchdb_id corresponding, to it.
        @location            = Location.new(p_params)
        @location.pouchdb_id = p_params["_id"]
        @location.source     = "mobile" # Right now, this API endpoint is only used by our mobile endpoint.
        @location.save(:validate => false)
      end

      @location.pouchdb_id = p_params["_id"]
      @location.save(:validate => false)

      ul = UserLocation.find_by_user_id_and_location_id(@current_user.id, @location.id)
      if ul.blank?
        ul = UserLocation.create(:user_id => @current_user.id, :location_id => @location.id, :source => "mobile", :assigned_at => Time.zone.now)
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

      # If the incoming visit object has an ID, then we should just update
      # its visited_at (the only thing that can change)
      if id.present? && @visit = Visit.find_by_id(id)
        t = Time.zone.parse(p_params[:visited_at])
        @visit.update_column(:visited_at, t)
      else
        # At this point, the visit does not exist. Let's check if its corresponding
        # location exists. We do this 2 ways:
        # 1. Check if :id exists
        # 2. Check if :_id (pouchdb_id) exists.
        # If neither exist, then we fail.
        if p_params[:location].blank?
          raise StandardError.new("The visit sync object must supply a Location key!") and return
        end

        # NOTE: We fail if we can't find the ID or PouchDB ID of a location.
        location = Location.find_by_id(p_params[:location][:id]) if p_params[:location][:id].present?
        location = Location.find_by_pouchdb_id(p_params[:location][:pouchdb_id]) if p_params[:location][:pouchdb_id].present?
        if location.blank?
          raise StandardError.new("We couldn't find an associated location for this visit from ID or PouchDB ID!") and return
        end

        p_params.delete(:location)
        t = Time.zone.parse(p_params[:visited_at])
        @visit = location.visits.where("DATE(visited_at) = ?", t.strftime("%Y-%m-%d")).first
        if @visit.blank?
          @visit = Visit.new(:location_id => location.id)
          @visit.source = "mobile"
        end

        @visit.visited_at = t
        @visit.save!
      end

      @visit.pouchdb_id = p_params["_id"]
      @visit.save(:validate => false)
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

      # If the report is blank then continue.
      next if p_params[:report].blank?


      breeding_site      = p_params[:report].delete(:breeding_site)
      elimination_method = p_params[:report].delete(:elimination_method)

      if id.present? && @inspection = Inspection.find_by_id(id)
        @inspection.breeding_site_id = breeding_site[:id]

        if p_params[:report][:before_photo].present? && p_params[:report][:before_photo].exclude?("base64")
          p_params[:report].delete(:before_photo)
        end
        if p_params[:report][:after_photo].present? && p_params[:report][:after_photo].exclude?("base64")
          p_params[:report].delete(:after_photo)
        end

        # TODO: This may be buggy.
        @inspection.attributes.merge!(p_params[:report])
        @inspection.identification_type = @inspection.status
        @inspection.source = "mobile"

        @inspection.save(:validate => false)

        if p_params[:report][:eliminated_at].present?
          t = Time.zone.parse(p_params[:report][:eliminated_at])
          @inspection.eliminated_at         = t
          @inspection.elimination_method_id = elimination_method[:id]
          @inspection.save(:validate => false)
        end
      else

        # At this point, this is a new inspection/report. Let's ensure that the visit exists.
        @visit = Visit.find_by_id(p_params[:visit][:id]) if p_params[:visit][:id].present?
        @visit = Visit.find_by_pouchdb_id(p_params[:visit][:pouchdb_id]) if p_params[:visit][:pouchdb_id].present?
        if @visit.blank?
          raise StandardError.new("We couldn't find an associated visit for this inspection from ID or PouchDB ID!") and return
        end

        # At this point, the visit exists.
        params = p_params[:report]
        params.delete(:report)
        @inspection = Inspection.new(params)
        @inspection.source = "mobile"
        @inspection.breeding_site_id = breeding_site[:id]
        @inspection.last_synced_at = @last
        @inspection.identification_type = @inspection.original_status
        @inspection.visit_id = @visit.id
        @inspection.source = "mobile"
        @inspection.save(:validate => false)
      end
    end

    # At this point, all measurements have saved. Let's update the column.
    @last_seq       = changes_params[:last_seq]
    @last_synced_at = Time.now.utc
    @inspection.update_columns({:last_synced_at => @last_synced_at, :last_sync_seq => @last_seq})
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
