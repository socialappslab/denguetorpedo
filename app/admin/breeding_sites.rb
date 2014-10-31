ActiveAdmin.register BreedingSite do
  #----------------------------------------------------------------------------
  # Model attributes
  #-----------------
  index do
    column "Portuguese", "description_in_pt"
    column "Spanish", "description_in_es"

    column "Number of reports with this breeding site" do |breeding_site|
      Report.all.find_all {|r| r.breeding_site_id == breeding_site.id}.count
    end

    column "Elimination methods" do |bs|
      table_for bs.elimination_methods do
        column "Portuguese", "description_in_pt"
        column "Spanish", "description_in_es"
        column "Points", "points"
        column "Number of reports with this elimination method" do |method|
          Report.all.find_all {|r| r.elimination_method_id == method.id}.count
        end
      end
    end

    default_actions
  end

  controller do
    def create
      create! do |format|
        format.html { redirect_to admin_breeding_sites_path }
      end
    end

    def update
      update! do |format|
        format.html { redirect_to admin_breeding_sites_path }
      end
    end
  end

  #----------------------------------------------------------------------------
  # View customizations
  #--------------------
  form do |f|
    f.inputs "Breeding Site" do
      f.input "description_in_pt", :as => :text, :input_html => { :size => 2, :rows => 2 }
      f.input "description_in_es", :as => :text, :input_html => { :size => 10, :rows => 2 }

      f.inputs "Elimination Methods" do
        f.has_many :elimination_methods,:allow_destroy => true, :heading => 'Elimination Methods', :new_record => true do |item|

          item.input :description_in_pt, :as => :text, :input_html => { :size => 2, :rows => 2 }
          item.input :description_in_es, :as => :text, :input_html => { :size => 2, :rows => 2 }
          item.input :points

          item.input :_destroy, :as => :boolean, :label => "Delete this elimination method?"
        end
      end
      f.input "string_id"
    end



    f.actions
  end


end
