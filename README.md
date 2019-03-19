# DengueChat

Dengue Torpedo is a Rails application that solves public health problems by engaging citizens to report public health risks by mobile phones and gaming tactics.

DengueChat is currently focused on solving the dengue/chikungunya/zika epidemic in 3rd world countries. A community in a city, say Managua, has a facilitator who manages a group of students in an after-school program. In the after-school program, students go house-to-house in their neighborhood, and inspect each room in the house for mosquito breeding sites. This can include barrels of water, unused tires full of water, or kitchen sink in the outdoors. These breeding sites are documented on paper, or mobile app, with a unique field identifier.

The students then educate the tenants on dangers of standing water and how this creates breeding grounds for larvae and pupae. Students return to each house and re-inspect the breeding sites to confirm if the breeding site was eliminated (standing water removed) or if it's still present.

After each visit, students transfer the paper report into an Excel file, and then upload to www.denguechat.org website. If a mobile app was used, then the data automatically syncs with denguechat.org server when a connection is found.

During this whole process, students can socialize with other students through a newsfeed-like interface in www.denguechat.org or within the mobile app.

By engaging with each other socially, and visualizing the data collected in the field, students and facilitators are empowered by creating change in their own communities.

## Database Architecture
To reflect the real-world scenario, we must design the database appropriately. Below I explain the function of each table (as of June 18, 2018):

```
"active_admin_comments" - DEPRECATED
"admin_users" - DEPRECATED
"breeding_sites" - hardcoded list of all potential breeding sites, such as water in tire, water in vase, water in kitchen sink, standing water on roof, barrel, etc.
"cities" - What city is this happening in?
"city_blocks" - NOT USED YET but Managua wanted to use this to organize the neighborhoods by city block.
"comments" - DEPRECATED
"conversations" - DEPRECATED
"conversations_users" - DEPRECATED
"countries" - What country is this happening in?
"csv_errors" - lists errors associated with the uploaded CSV, if any.
"csv_reports" - DEPRECATED
"csvs" - stores the uploaded spreadsheet.
"device_sessions" - Stores authentication using JWT token for the mobile app
"districts" - What district does the neighborhood belong to?
"documentation_sections" - DEPRECATED
"elimination_methods" - Hardcoded method of eliminating a breeding site.
"elimination_types" - DEPRECATED
"houses" - DEPRECATED
"inspections" - An inspection is a conceptual connection between a visit and some breeding site. In other words, a visit has many breeding sites through some inspection.
"likes" - Likes associated to a Post
"locations" - a location, either a house, a monument, or a landmark.
"memberships" - DEPRECATED
"messages" - DEPRECATED
"neighborhoods" - a neighborhood, such as Ariel Darce in the city of Managua.
"notices" - DEPRECATED
"notifications" - DEPRECATED
"organizations" - Organizations around the world using DengueChat. Helps separate the business logic and scope cities and teams to that organization. For instance, SSI or AMOS Nicaragua
"posts" - A post in the newsfeed.
"prize_codes" - DEPRECATED
"prizes" - DEPRECATED
"recruitments" - DEPRECATED
"reports" - DEPRECATED in favor for Inspection
"reports_users" - DEPRECATED
"team_memberships" - what user belongs to what team?
"teams" - Teams, such as "Brigada 8, Managua"
"user_locations" - NOT USED YET. What user is assigned to what location?
"user_notifications" - DEPRECATED
"users" - a user of the app. Can be a student, a facilitator or an admin
"visits" - A "Visit" instance is the real-world representation of a physical visit to some location. A visit, naturally, has several inspections throughout the house and over several dates.
```

To better understand how Visit, Location and Inspections relate to each other, take a look at this visual representation:

![Relationship_between_visit_location_inspections](relationship_between_visit_location_inspections.jpg)



### Moving from Report to Inspection
As of June 23, 2017, we create a 1-1 association between Report and Inspection.
This association means we're carefully setting different data on 2 different models, as can be observed in SpreadsheetParserWorker:

https://github.com/socialappslab/denguetorpedo/blob/d3eb4573b8eaf869c75b10dff639d14e624ce6c7/app/workers/spreadsheet_parsing_worker.rb#L105-L149

To simplify this and accelerate development, I propose we deprecate Report model
in favor of Inspection. To achieve this, I propose we migrate the columns on Report to Inspection.

NOTE: This has essentially happened as of June 2018.

## Redis and Background Jobs
Currently, DengueChat uses Redis to display Green House charts. Why? Because
the calculations required to display these charts are intensive, and so are
delegated to run daily, in the background, and the results stores in an Redis in-memory store.

Make sure that the following Sidekiq workers are running (look at the Sidekiq dashboard to see if they are scheduled, e.g., https://www.denguechat.org/7XpBp7Bgd2cd/scheduled):

```
app/workers/green_location_rankings_worker.rb
app/workers/green_location_series_worker.rb
```

These should be running every day (they do once you start them first) and calculate the Number of Green Houses for that day. If they are not scheduled to run, make sure you run them at least once manually. Each workers schedules himself to run again in a day at the end of the process.  

```
require "sidekiq"
include GreenLocationSeries
GreenLocationSeriesWorker.new.perform
include GreenLocationRankings GreenLocationRankingsWorker.new.perform
```

You can verify if workers are running by visiting `www.denguechat.org/7XpBp7Bgd2cd`.

To understand what data is displayed from Redis, visit https://www.denguechat.org/cities/5 and notice the chart "Gráfico de casas verdes". This chart uses the API endpoint `GET /api/v0/graph/green_locations`
located in `/api/v0/graphs_controller.rb` and the `GreenLocationSeries` model
that uses Redis data that is generated from `GreenLocationSeriesWorker`.

Now, look at the table "Casas Verdes", which displays the users with top green houses. This data is fetched from `GreenLocationRankings` model that uses Redis data that is generated from `GreenLocationRankingsWorker`.

## REDIS backups

It is very hard to reconstruct this data from scratch because it would require
you to know what visits and inspections were created on what date, and how that corresponds to previous inspections and visits. Doable but very hard. For this reason, I highly recommend restoring from Redis backup.

The Redis backup taken on June 15, 2018 (before migration first migration out of HEROKU) is available at this [Google Drive URL](https://drive.google.com/open?id=16Ti3b8IOcXZ0b7NsenGZsHo5eAXNWhTC)

To restore REDIS, you can follow this [how-to](https://community.pivotal.io/s/article/How-to-Backup-and-Restore-Open-Source-Redis). To follow this how-to to restore a backup in the docker container of our [DengueChat Docker Compose](https://github.com/socialappslab/denguechat-compose), you have to build the container and start it once, then: 

1. Enter the container: `docker exec -t /bin/sh denguetorpedo-redis`
2. Edit the configuration to set the variable `appendonly` to `no`: `nano /opt/bitnami/redis/etc/redis.conf`
3. Follow the how-to we suggested above. 

## REDIS KEYS

The following is a list of keys we use in REDIS, with examples of their values: 

```
"processes" => [SET] process names of sidekiq processes
"queues" => [SET] key names of sidekiq workers
"schedule" => [ZSET] workers in schedule
"stat:failed" => [STRING] number of stats calculations that failed
"stat:failed:__DATE__" => [STRING] number of stats calculations that failed on DATE
"stat:processed" => [STRING] number of stats calculations that were processed 
"stat:processed:__DATE__" => [STRING] number of stats calculations that were processed on DATE
"__IP or DOMAIN__:15:8076773734be" => [HASH] infor about last running of workers
"__IP or DOMAIN__:15:8076773734be:workers" => [HASH] sidekiq workers
"cities:__CITYID__:green_locations:timeseries:weekly" => [ZSET] Contains the weekly count of green houses for CITYID, over the past 30 weeks 

  127.0.0.1:6379> zrange "cities:4:green_locations:timeseries:weekly" 25 30
  1) "20190210:478"
  2) "20190217:478"
  3) "20190224:478"
  4) "20190303:478"
  5) "20190310:478"
  6) "20190317:478"

"green_location_rankings:__CITYNAME__" => [ZSET] Contains a set of green houses calculations

  127.0.0.1:6379> zrange "green_location_rankings:managua" 230 233  
  1) "337"
  2) "253"
  3) "826"

"neighborhoods:__NEIGHBORHODDID__:green_locations:timeseries:daily" => [ZSET] daily number of green houses for neighborhood
```

## Mobile App
The mobile app is stored in separate repositories, but communicates with this repo through several API endpoints. Most of the API endpoints are self-explanatory, as they fetch the location, visit or inspections.

What is not obvious is how the actual offline-to-online syncing happens. I explain this process below.

### Syncing
In offline mode, the data is stored on the mobile app until an internet connection is found. When an internet connection is found, the mobile app makes
a PUT requests to the following API endpoints:

```
PUT /api/v0/sync/post - when a user created a new post or liked an existing post.
PUT /api/v0/sync/location - when a user creates a new location or updates an existing location
PUT /api/v0/sync/visit - when a user creates a new visit or updates an existing location
PUT /api/v0/sync/inspection - when a user creates a new inspection or updates an existing location
```

If a successful sync has occurred, then the respective Resource will get its instance updated with `:last_synced_at => Time.now.utc, :last_sync_seq => @last_seq` where `@last_seq` is a PouchDB sequence id passed in the parameters.

#### PouchDB as sync database in mobile app
The app uses PouchDB to store data and send data to the server. As a result, the paramenters that are sent with HTTP PUT requests will resemble the structure that PouchDB imposes. You can learn more here https://pouchdb.com/guides/changes.html, but basically, PouchDB stores *all* changes, whether it's a new Post or an existing Post, in a `changes` array, which encodes *changes* to the resource. This `changes` array keeps growing until an internet connection is found, a successful sync occurs, and the mobile app notifies PouchDB that a successful sync happened, and then PouchDB resets the `changes` array to empty. The cycle repeats until another successful sync happens.


#### Structure of HTTP PUT request for Post resource
Specifically, I show you the structure of the params when syncing a Post:

```

{
  "changes": {
    "last_seq": "PouchDB id that helps us store the sync state consistent between server (Rails server) and client (mobile app)",
    "results": [
      {
        "doc": {
          "id": "ID of the Post/Location. May be empty",
          "user_id": "What is the user's ID?",
          "neighborhood_id": "What neighborhood is this?",
          "photo": "Relevant to Post if there is a photo. Comes in as a Base64 encoding.",
          "content": "Content of the Post",
          "liked": "May be 'true' or 'false' or empty"
        }
      },
      {
        "doc": {
        }
      },
      {
        "doc": {
        }
      }
    ]
  }
}

```



#### Structure of HTTP PUT request for Location resource
Specifically, I show you the structure of the params when syncing a Location:

```

{
  "changes": {
    "last_seq": "PouchDB id that helps us store the sync state consistent between server (Rails server) and client (mobile app)",
    "results": [
      {
        "doc": {
          "id": "ID of the Post/Location. May be empty",
          "_id": "Unique PouchDB ID that we store to help us associate the location with visit if the location is new and hasn't been persisted to SQL database yet (imagine offline scenario where Location + Visit + Inspection is created and then syncing occurs asynchronously with no guarantee that Location will be persisted before Visit...)",
          "user_id": "What is the user's ID?",
          "address": "What's the address? May be 'N001002' or '10 Berkeley Way'",
          "neighborhood_id": "What neighborhood is this?",
          "city_id": "What neighborhood is this?",
          "questions": "Questions that are specific to a location. Some cities ask that. See questionnaire_for_membership(membership) in Location model to understand the structure",
        }
      },
      {
        "doc": {
        }
      },
      {
        "doc": {
        }
      }
    ]
  }
}

```


#### Structure of HTTP PUT request for Visit resource
Specifically, I show you the structure of the params when syncing a Visit:

```

{
  "changes": {
    "last_seq": "PouchDB id that helps us store the sync state consistent between server (Rails server) and client (mobile app)",
    "results": [
      {
        "doc": {
          "id": "ID of the Post/Location. May be empty",
          "_id": "Unique PouchDB ID that we store to help us associate the location with visit if the location is new and hasn't been persisted to SQL database yet (imagine offline scenario where Location + Visit + Inspection is created and then syncing occurs asynchronously with no guarantee that Location will be persisted before Visit...)",
          "visited_at": "When was it visited?",
          "location": {
            "id": "What is the ID of the location? Should be present with ID from our Rails SQL database. If it's not present, then it may be a new location",
            "pouchdb_id": "If id is not present, then this may be a new Location. We use pouchdb_id to check if we have something that matches this pouchdb_id, and if not, then we create a new location."
          }
        }
      },
      {
        "doc": {
        }
      },
      {
        "doc": {
        }
      }
    ]
  }
}

```



#### Structure of HTTP PUT request for Inspection resource
Specifically, I show you the structure of the params when syncing a Inspection:

```

{
  "changes": {
    "last_seq": "PouchDB id that helps us store the sync state consistent between server (Rails server) and client (mobile app)",
    "results": [
      {
        "doc": {
          "id": "ID of the Post/Location. May be empty",
          "_id": "Unique PouchDB ID that we store to help us associate the location with visit if the location is new and hasn't been persisted to SQL database yet (imagine offline scenario where Location + Visit + Inspection is created and then syncing occurs asynchronously with no guarantee that Location will be persisted before Visit...)",
          "before_photo": "Comes in as a Base64 encoding. May be empty.",
          "after_photo": "Comes in as a Base64 encoding. May be empty.",
          "visit": {
            "id": "SQL id",
            "pouchdb_id": "PouchDB id"
          },
          "report": {
            ... See Inspection validations that must be present to understand what keys must be present...
          }
          "eliminated_at": "When was this eliminated? May be empty."
          "breeding_site": {
            "id": "SQL ID"
          },
          "elimination_method": {
            "id": "SQL ID",
          }
        }
      },
      {
        "doc": {
        }
      },
      {
        "doc": {
        }
      }
    ]
  }
}

```



## CSV Import
There are 2 ways to import CSV files: one-by-one or batch. I discuss each in turn. The format of CSV should be the following: `/assets/forma_csv.xlsx`.

The general process is:
1. Upload one or more CSV,
2. Create instance of `Spreadsheet`,
2. SpreadsheetParsingWorker parses the CSV and creates `Inspection` and (maybe) `Visit` instances,
4. Updates `parsed_at` column of `Spreadsheet` instance.

### One-by-one
The functionality for one-by-one is located at http://localhost:5000/csv_reports/new. The view is managed by `csv_reports/new` and the controller is located at `api/v0/csv_reports_controller.rb`.

The controller really just does the formality of creating the Spreadsheet instance. It then hands the work off to `SpreadsheetParsingWorker.perform_async(@csv_report.id)`, which will be discussed below.

### Batch
The functionality for batch is located at http://localhost:5000/csv_reports/batch. The view is managed by `csv_reports/batch` and the controller is located `api/v0/csv_reports_controller.rb`.

The controller's function is really similar one-by-one in that it creates the
Spreadsheet instance and hands the heavy lifting to `SpreadsheetParsingWorker.perform_async(@csv_report.id)`

### SpreadsheetParsingWorker
The worker is responsible for parsing and structuring the CSV data into existing
Rails models. This is easier said than done. To explain its multi-faceted csv_parsing steps, I will the boundaries of the problem:


### The column 'tipo' encodes the breeding site
In `Spreadsheet#extract_content_from_row(row)`, we extract `breeding_site` via:

```
breeding_site     = row.select {|k,v| k.include?("tipo")}.values[0].to_s
```

#### Worker requires specific breeding sites
This is defined in `Spreadsheet` as:

```
def self.accepted_breeding_site_codes
  return ["a", "b", "l", "m", "p", "t", "x"] + self.clean_breeding_site_codes
end
```

where `Spreadsheet.clean_breeding_site_codes = ['n']`. If you want to add a new
breeding code, then you must create a corresponding `BreedingSite` instance with the corresponding code. Why? Because SpreadsheetParsingWorker takes the identified code from `accepted_breeding_site_codes` and maps it to an existing
instance in the function:

```
def self.extract_breeding_site_from_row(row_content)
  type = row_content[:breeding_site].strip.downcase

  if type.include?("a")
    breeding_site = BreedingSite.find_by_string_id(BreedingSite::Types::DISH)
  elsif type.include?("b")
    breeding_site = BreedingSite.find_by_code("B")
  elsif type.include?("l")
    breeding_site = BreedingSite.find_by_string_id(BreedingSite::Types::TIRE)
  elsif type.include?("m")
    breeding_site = BreedingSite.find_by_string_id(BreedingSite::Types::DISH)
  elsif type.include?("p")
    breeding_site = BreedingSite.find_by_code("P")
  elsif type.include?("t")
    breeding_site = BreedingSite.find_by_string_id(BreedingSite::Types::SMALL_CONTAINER)
  end

  return breeding_site
end
```


#### Worker allows for breeding site code to be followed by a number (E.g. B7)
The cool thing about the worker is that it recognizes that `B7` is BreedingSite with code `B` and `field_identifier` is 7.

What's the `field_identifier`? Look at L95 of spreadsheet_parsing_worker.rb:

```
# We say that the report has a field identifier if the breeding site CSV column
# also has an integer associated with it.
field_id = nil
field_id = raw_breeding_code if raw_breeding_code =~ /\d/
```

raw_breeding_code comes from `tipo` column via the method `Spreadsheet.extract_content_from_row(row)` and will typically look like `b7` or `b75`. So `field_id = b75` since `raw_breeding_code =~ /\d/` checks if the `tipo` column entry has a number embedded in it.

How do we use `field_id`? The `field_id` is used to search for the corresponding
CSV inspection instance here:

```
@csv.inspections.find_by(:field_identifier => field_id, :visit_id => v.id)
```

If it doesn't exist, then a new `Inspection` instance is created with that field identifier!

NOTE: To understand how an `Inspection` differs from a `Visit`, I recommend reading the top-level comment in `inspection.rb` model.

### Example
It turns out that the parsing code already allows for breeding codes like `B7`.

What it does is to extract the letter (`B`) and map it to an existing `BreedingSite` instance with that code (so make sure if you introduce a new letter that you create a corresponding `BreedingSite` in production with that code.

If a number is present, like it is in `B7`, then the parser will use `b7` as a "field identifier" and create an `Inspection` instance with the `field_identifier` column set to `b7`.

So let's take an example: Paraguay creates a new code, say H, and you create a new `BreedingSite` instance like: `BreedingSite.create(..., :code => "H", ...)`. Then, Paraguay users upload CSV that have `tipo` column with entries like `H32`. This will create a new `Inspection` instance with `field_identifier="H32"`. You can then query the DB and get all inspections for a specific CSV:


Get all inspections associated to this CSV: @csv.inspections

Get data on the different breeding sites and frequency:
@csv.inspections.pluck(:field_identifier)




## Docker Management
### DengueChat app
1. Navigate to http://149.165.156.246:9002/#/containers
2. Ask Cristhian for creds
3. Click Containers > denguetorpedo > console > Connect
4. cd home/dengue/denguetorpedo

### DengueChat Redis instances
The Redis backup, taken on June 15, 2018, is available at this URL:

https://drive.google.com/open?id=16Ti3b8IOcXZ0b7NsenGZsHo5eAXNWhTC

The instructions for restoring this backup are available here:

https://www.digitalocean.com/community/tutorials/how-to-back-up-and-restore-your-redis-data-on-ubuntu-14-04

However, a few issues need to be resolved before this is doable. See https://github.com/socialappslab/denguetorpedo/issues/835 for more.




## SMS
We're using a custom gateway hosted on an Android phone with a custom Android app
written on it. The app essentially waits for incoming texts, and relays them to
our (Rails) app server through a POST request to /reports/gateway.

As of 2014-07-18, this setup is only deployed in Rio de Janeiro, Brazil.

## Videos
We're keeping a visual history of denguetorpedo.com by taking video snapshots
of specific pages. These videos are compressed as .swf files in `/videos`
directory.


## Dealing with Redis service
If you ever need to restore a Redis database to Portainer, then follow these directions:

0. Turn off redis server using `redis-cli -a password` and then run the command `shutdown nosave` (https://redis.io/commands/shutdown) to avoid save the information (NOTE: This is for empty databases).
1. Save the database into dump.rdb
2. scp it into the Docker instance. The data directory for `http://149.165.156.246:9002/#/containers/c8d6d52908c81238ee12d702feb2bd1f6857edc12a3a8734d516fb0f9d54a00a/console` is presently `/opt/bitnami/redis/data`.
3. Run chown redis:redis dump.rdb && chmod 660 dump.rdb
4. Restart the Docker container
5. Run `reids-cli -a [password]` and then run the command `BGREWRITEAOF`. Run `info` and make sure that `aof_rewrite_in_progress` is 0 (e.g. it finished)
6. Now restart the Docker container.
7. Make sure that `dump.rdb` has some size (otherwise, it means it was overwritten).
