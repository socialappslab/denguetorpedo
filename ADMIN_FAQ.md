# How do you create an organization?
To create an organization, you need to run the following command on the rails console

```sh
cd $PATH_APP_BASE_DIR
rails console
Loading production environment (Rails 4.2.0)
irb(main):001:0> org = Organization.create(:name => “Organization Name”)
```

Then, for every user that should be part of the organization, you need to create a Membership instance:

```sh
irb(main):001:0> u = User.find_by_username(“username”)
irb(main):001:0> Membership.create(:user_id => u.id, :organization_id => org.id, :role => “admin”)
```

This will display “Organization Name” in the User’s Profile dropdown:

# How do you change the name of the organization?

Login as an admin, and visit the organization from your profile dropdown. You will be able to then change the name.

# How do you change the role of a user?
Login as an admin, and visit the organization from your profile dropdown. Then click “Usuarios” and change their role for the organization.

# How do you create a city?

To create an city, you need to run the following command in the rails console:

```sh
irb(main):001:0> city = City.create(:name => “Asunción”, :state => “Asunción”, :country_id => “...”)
```

# How do you create a neighborhood?
To create a neighborhood, you need to run the following command:
```sh
irb(main):001:0> neighborhood = Neighborhood.create(:name => “Test Neighborhood”, :city_id => city.id. :photo => “...”)
```

When create does not work, you can also do the creation of the object step by step. This also applies to updating a record. 

```sh
irb(main):001:0> n = Neighborhood.new
irb(main):001:0> n.name = "Managua"
irb(main):001:0> n.photo = open("https://media1.britannica.com/eb-media/68/193868-004-79687D6F.jpg")
irb(main):001:0> n.save!
```

# How do you assign a user to a community/neighborhood and city?

Visit https://www.denguechat.com/organizations/users and click “Agregate nuevo usuario”. This will allow you to add their username and choose a community. The community is associated with a city so the user will be automatically enrolled in the community’s city.

NOTE: If you want an existing user to change their community, ask them to login and visit “Mi Perfil” to change their neighborhood. The neighborhood can also be changed programmatically by the developer.

# How do you create a new team?

Visit https://www.denguechat.com/teams and click “Cree un equipo”.

# How do you get a user to join a team?

Ask them to login and find a team they like. Then click “Join team”.
