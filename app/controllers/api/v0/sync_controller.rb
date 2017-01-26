
class API::V0::SyncController < API::V0::BaseController
  skip_before_filter :authenticate_user_via_device_token
  before_action :authenticate_user_via_jwt
  before_action :current_user_via_jwt


  #-------------------------------------------------------------------------------------------------
  # GET /api/v0/sync?event_id=...

  def posts
  end

  #-------------------------------------------------------------------------------------------------
  # GET /api/v0/sync/measurement?event_id=...

  # Two keys come in:
  # 1. changes which is the Changes Feed in PouchDB (https://pouchdb.com/guides/changes.html)
  # 2. sync_status which contains last_synced_at timestamp, if any.
  def post
    # Iterate over each change to the measurement, storing it in
    # TODO: How many changes will there be???
    changes_params["results"].each do |result|
      p_params = result["doc"].with_indifferent_access
      pid      = p_params[:id]

      puts "\n\n\npid: #{pid}\n\n\n"
      puts "@post = Post.find_by_id(pid): #{Post.find_by_id(pid)}\n\n\n\n"

      # If the post is present, then we can only really update a like or comment on it.
      if pid.present? && @post = Post.find_by_id(pid)

        puts "\n\n\n\np_params[:liked]: #{p_params[:liked]}\n\n\n\n"
        if p_params[:liked].to_s.present?
          existing_like = @post.likes.find {|like| like.user_id == @current_user.id }
          puts "existing_like: #{existing_like.inspect}\n\n\n\n"
          if existing_like.present? && p_params[:liked].to_s == "false"
            puts "Like exists and liked = false"
            existing_like.destroy
          elsif existing_like.blank? && p_params[:liked].to_s == "true"
            puts "No like exists and liked = true"
            Like.create(:user_id => @current_user.id, :likeable_id => @post.id, :likeable_type => Post.name)
            Analytics.track( :user_id => @current_user.id, :event => "Liked a post", :properties => {:post => @post.id}) if Rails.env.production?
          end
        end

      else
        @post                 = Post.new(p_params)
        @post.user_id         = @current_user.id
        @post.neighborhood_id = Neighborhood.find(p_params[:neighborhood_id]).id

        base64_image = p_params[:compressed_photo]
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
  # GET /api/v0/sync/measurement?event_id=...

  # Two keys come in:
  # 1. changes which is the Changes Feed in PouchDB (https://pouchdb.com/guides/changes.html)
  # 2. sync_status which contains last_synced_at timestamp, if any.
  def measurement
    @event = @screening_company.events.find_by_id(params[:event_id])

    # We extract a few things
    last_synced_at = sync_status_params[:last_synced_at]
    if last_synced_at.present?
      # DO STUFF...What?
    end

    # Iterate over each change to the measurement, storing it in
    # TODO: How many changes will there be???
    changes_params["results"].each do |result|
      m_params = result["doc"].with_indifferent_access
      mid      = m_params[:id]
      if mid.present?
        @measurement = @event.measurements.find_by_id(mid)

        params_to_save = m_params.slice(*Clovi::Measurement.phi_attributes).except(:fasting_glucose, :nonfasting_glucose).permit(*Clovi::Measurement.phi_attributes)
        if m_params[:fasting_glucose]
          params_to_save.merge!({:fasting => true, :glucose => m_params[:fasting_glucose]})
        elsif m_params[:nonfasting_glucose]
          params_to_save.merge!({:fasting => false, :glucose => m_params[:nonfasting_glucose]})
        end

        @measurement.attributes = params_to_save
        if @measurement.save
          begin
            @measurement.sync(params_to_save, current_screener)
          rescue Clovi::Error::TrueVaultNoSuchDocumentError => err
            raise API::V0::Error.new(err.message, 422) and return
          rescue StandardError => e
            Rails.logger.error "[StandardError] Output = #{e.inspect}"
            raise API::V0::Error.new("Something went wrong on our end. Please try again!", 422) and return
          end
        else
          raise "SOMETHING WENT WRONG #{@measurement.inspect}" and return
        end
      else
        # TODO:
        # If the participant_id does not exist, then this
        # means the participant was created via offline storage.
        # We need to match the document ID to the participant in
        # our database.
        raise "This measurement does not exist... TODO" and return
      end
    end

    # At this point, all measurements have saved. Let's update the column.
    @last_seq       = changes_params[:last_seq]
    @last_synced_at = Time.now.utc
    @measurement.update_columns({:last_synced_at => @last_synced_at, :last_sync_seq => @last_seq})
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
