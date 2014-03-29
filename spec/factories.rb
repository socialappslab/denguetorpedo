FactoryGirl.define do
	factory :user do |user|
		user.first_name { Faker::Name.first_name }
		user.last_name { Faker::Name.last_name }
		user.email { Faker::Internet.email }
		user.nickname { Faker::Name.first_name }
		user.middle_name { Faker::Name.first_name }
		user.phone_number { Faker::PhoneNumber.phone_number[0..19] }
		user.neighborhood { Neighborhood.first }
		user.password "denguewarrior"
		user.password_confirmation "denguewarrior"
		user.neighborhood { Neighborhood.first }
		user.carrier "XXX"
		user.prepaid true
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
		neighborhood { Neighborhood.first }
		association :location
		profile_photo_file_name "File name"
		profile_photo_content_type "image/png"
		profile_photo_file_size 1024
		profile_photo_updated_at Time.new
	end

	factory :location do
		street_type "Rua"
		street_name "Tatajuba"
		street_number "50"
	end

	factory :neighborhood do |n|
		n.name "Mare"
	end

	factory :notice do
		title "Title"
		description "Description"
		summary "Summary"
		location "DT Headquarter"
		date Date.new
	end

	factory :report do
		report "description"
		created_at Time.now
		status_cd 0
		association :reporter, factory: :user
		before_photo_file_name "File name"
		before_photo_content_type "image/png"
		before_photo_file_size 1024
		before_photo_updated_at Time.now
		sms false
		completed_at Time.now

		factory :sms do
			sms true
			status_cd 2
		end

		factory :identified do
			elimination_type "Type"
			association :location

			factory :verified_identified do
				isVerified true
			end

			factory :problem_identified do
				isVerified false
			end
		end

		factory :eliminated do
			elimination_method "Method"
			status_cd 1
			association :location
			after_photo_file_name "File name"
			after_photo_content_type "image/png"
			after_photo_file_size 1024
			after_photo_updated_at Time.now
			association :eliminator, factory: :user
			factory :verified_eliminated do
				is_resolved_verified true
				resolved_verified_at Time.now
				association :resolved_verifier, factory: :user
			end

			factory :problem_eliminated do
				isVerified false
			end
		end
	end
end
