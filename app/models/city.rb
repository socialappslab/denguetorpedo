# -*- encoding : utf-8 -*-
class City < ActiveRecord::Base
  attr_accessible :name, :photo, :state, :state_code, :country, :time_zone, :as => :admin

  #----------------------------------------------------------------------------

  module Countries
    MEXICO    = "Mexico"
    BRAZIL    = "Brazil"
    NICARAGUA = "Nicaragua"
    PARAGUAY = "Paraguay"
  end

  #----------------------------------------------------------------------------  

  has_many :neighborhoods
  has_many :city_blocks
  has_many :locations
  has_many :districts

  #----------------------------------------------------------------------------

  validates :name,       :presence => true
  validates :state,      :presence => true
  validates :state_code, :presence => true
  validates :time_zone,  :presence => true

  # TODO: Deprecate this after March 1st, 2015
  validates :country, :presence => true

  #----------------------------------------------------------------------------

  has_attached_file :photo
  do_not_validate_attachment_file_type :photo

  #----------------------------------------------------------------------------

  def localized_country_name
    I18n.t("countries.#{self.country.downcase}")
  end

  def geographical_name
    "#{self.name}, #{self.localized_country_name}"
  end

  #----------------------------------------------------------------------------

  def last_visited_city_blocks
    stats = ActiveRecord::Base.connection.execute("
    select 
        city_block_name, 
        neighborhood_id, 
        neighborhood_name, 
        sum(visit_count) as visit_count, 
        max(last_visit_date) as last_visit_date, 
        min(first_visit_date)  as first_visit_date  
    from 
        (

            (
                select 
                    cb.name as city_block_name, cb.neighborhood_id as neighborhood_id, n.name as neighborhood_name, 
                    count(*) as visit_count, max(v.visited_at) as last_visit_date , min(v.visited_at)  as first_visit_date  
                from visits v, locations l, city_blocks cb, neighborhoods n
                where
                    v.location_id = l.id
                    and l.city_block_id = cb.id
                    and cb.city_id = 9
                    and cb.neighborhood_id = n.id
                group by cb.id, cb.name, cb.neighborhood_id, n.name
                order by count(*) desc
            )
        union
            (   
                select 
                    left(l.address,5) as city_block_name, l.neighborhood_id as neighborhood_id, n.name as neighborhood_name, 
                    count(*) as visit_count, max(v.visited_at) as last_visit_date , min(v.visited_at)  as first_visit_date  
                from visits v, locations l, neighborhoods n
                where
                    v.location_id = l.id
                    and l.city_id = #{self.id}
                    and l.neighborhood_id = n.id
                    and l.city_block_id is null
                group by l.address, l.id, l.neighborhood_id, n.name
                order by count(*) desc
            )
        ) as visit_statistics
    group by city_block_name, neighborhood_id, neighborhood_name
    order by last_visit_date desc
    limit 5;
    ")
  end

  def less_visited_city_blocks
    stats = ActiveRecord::Base.connection.execute("
    select 
        city_block_name, 
        neighborhood_id, 
        neighborhood_name, 
        sum(visit_count) as visit_count, 
        max(last_visit_date) as last_visit_date, 
        min(first_visit_date)  as first_visit_date  
    from 
        (

            (
                select 
                    cb.name as city_block_name, cb.neighborhood_id as neighborhood_id, n.name as neighborhood_name, 
                    count(*) as visit_count, max(v.visited_at) as last_visit_date , min(v.visited_at)  as first_visit_date  
                from visits v, locations l, city_blocks cb, neighborhoods n
                where
                    v.location_id = l.id
                    and l.city_block_id = cb.id
                    and cb.city_id = #{self.id}
                    and cb.neighborhood_id = n.id
                group by cb.id, cb.name, cb.neighborhood_id, n.name
                order by count(*) desc
            )
        union
            (   
                select 
                    left(l.address,5) as city_block_name, l.neighborhood_id as neighborhood_id, n.name as neighborhood_name, 
                    count(*) as visit_count, max(v.visited_at) as last_visit_date , min(v.visited_at)  as first_visit_date  
                from visits v, locations l, neighborhoods n
                where
                    v.location_id = l.id
                    and l.city_id = 9
                    and l.neighborhood_id = n.id
                    and l.city_block_id is null
                group by l.address, l.id, l.neighborhood_id, n.name
                order by count(*) desc
            )
        ) as visit_statistics
    group by city_block_name, neighborhood_id, neighborhood_name
    order by sum(visit_count) asc, last_visit_date desc
    limit 5;
    ")
  end

  def last_visited_city_blocks_barrios(id_barrio)
    stats = ActiveRecord::Base.connection.execute("
    select 
        city_block_name, 
        neighborhood_id, 
        neighborhood_name, 
        sum(visit_count) as visit_count, 
        max(last_visit_date) as last_visit_date, 
        min(first_visit_date)  as first_visit_date  
    from 
        (

            (
                select 
                    cb.name as city_block_name, cb.neighborhood_id as neighborhood_id, n.name as neighborhood_name, 
                    count(*) as visit_count, max(v.visited_at) as last_visit_date , min(v.visited_at)  as first_visit_date  
                from visits v, locations l, city_blocks cb, neighborhoods n
                where
                    v.location_id = l.id
                    and l.city_block_id = cb.id
                    and cb.city_id = 9
                    and cb.neighborhood_id = #{id_barrio}
                group by cb.id, cb.name, cb.neighborhood_id, n.name
                order by count(*) desc
            )
        union
            (   
                select 
                    left(l.address,5) as city_block_name, l.neighborhood_id as neighborhood_id, n.name as neighborhood_name, 
                    count(*) as visit_count, max(v.visited_at) as last_visit_date , min(v.visited_at)  as first_visit_date  
                from visits v, locations l, neighborhoods n
                where
                    v.location_id = l.id
                    and l.city_id = #{self.id}
                    and l.neighborhood_id = #{id_barrio}
                    and l.city_block_id is null
                group by l.address, l.id, l.neighborhood_id, n.name
                order by count(*) desc
            )
        ) as visit_statistics
    group by city_block_name, neighborhood_id, neighborhood_name
    order by last_visit_date desc
    limit 5;
    ")
  end

  def less_visited_city_blocks_barrios(id_barrio)
    stats = ActiveRecord::Base.connection.execute("
    select 
        city_block_name, 
        neighborhood_id, 
        neighborhood_name, 
        sum(visit_count) as visit_count, 
        max(last_visit_date) as last_visit_date, 
        min(first_visit_date)  as first_visit_date  
    from 
        (

            (
                select 
                    cb.name as city_block_name, cb.neighborhood_id as neighborhood_id, n.name as neighborhood_name, 
                    count(*) as visit_count, max(v.visited_at) as last_visit_date , min(v.visited_at)  as first_visit_date  
                from visits v, locations l, city_blocks cb, neighborhoods n
                where
                    v.location_id = l.id
                    and l.city_block_id = cb.id
                    and cb.city_id = #{self.id}
                    and cb.neighborhood_id = #{id_barrio}
                group by cb.id, cb.name, cb.neighborhood_id, n.name
                order by count(*) desc
            )
        union
            (   
                select 
                    left(l.address,5) as city_block_name, l.neighborhood_id as neighborhood_id, n.name as neighborhood_name, 
                    count(*) as visit_count, max(v.visited_at) as last_visit_date , min(v.visited_at)  as first_visit_date  
                from visits v, locations l, neighborhoods n
                where
                    v.location_id = l.id
                    and l.city_id = 9
                    and l.neighborhood_id = #{id_barrio}
                    and l.city_block_id is null
                group by l.address, l.id, l.neighborhood_id, n.name
                order by count(*) desc
            )
        ) as visit_statistics
    group by city_block_name, neighborhood_id, neighborhood_name
    order by sum(visit_count) asc, last_visit_date desc
    limit 5;
    ")
  end


end
