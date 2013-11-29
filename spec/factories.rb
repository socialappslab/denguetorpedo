FactoryGirl.define do
	factory :user do |user|
		user.first_name { Faker::Name.first_name }
		user.last_name { Faker::Name.last_name }
		user.email { Faker::Internet.email }
		user.phone_number { Faker::PhoneNumber.phone_number[0..19] }
		user.password "denguewarrior"
		user.password_confirmation "denguewarrior"
		association :house
		role "morador"
		profile_photo_file_name "File name"
		profile_photo_content_type "image/png"
		profile_photo_file_size 1024
		profile_photo_updated_at Time.new

		factory :admin do
			role "admin"
		end

		factory :coordinator do
			role "coordenador"
		end

		factory :sponsor do
			role "lojista"
		end

		factory :verifier do
			role "verificador"
		end

		factory :visitor do
			role "visitante"
		end
	end

	factory :prize do
		prize_name "Prize"
		cost 100
		stock 100
		description "Description"
		association :user
	end

	factory :house do
		name "Rede Trel"
		association :location
		profile_photo_file_name "File name"
		profile_photo_content_type "image/png"
		profile_photo_file_size 1024
		profile_photo_updated_at Time.new
	end

	factory :location do |location|
		location.street_type "Rua"
		location.street_name "Tatajuba"
		location.street_number "50"
		location.latitude 0
		location.longitude 0
	end

	factory :neighborhood do |n|
		n.name "Mare"
	end

	factory :notice do |notice|
		notice.title "Title"
		notice.description "Description"
		notice.summary "Summary"
		notice.location "DT Headquarter"
		notice.date Date.new
	end
end