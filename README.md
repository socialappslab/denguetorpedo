# Dengue Torpedo

Dengue Torpedo is a rails application that tries to solve public health problems by engaging citizens to report
public health risks by mobile phones and gaming tactics.

## SMS
We're using a custom gateway hosted on an Android phone with a custom Android app
written on it. The app essentially waits for incoming texts, and relays them to
our (Rails) app server through a POST request to /reports/gateway.

As of 2014-07-18, this setup is only deployed in Rio de Janeiro, Brazil.

## Videos
We're keeping a visual history of denguetorpedo.com by taking video snapshots
of specific pages. These videos are compressed as .swf files in `/videos`
directory.

## Getting Started
TODO TODO

## Database Architecture
Conceptually, a `Visit` instance to some `Location` instance will generate many breeding site `Report`s. A `Report` instance defines the evolution of a breeding site and so will change over several `Visit`s. The `Inspection` instance defines the state of the breeding site at any given time by associating the `Report` with a `Visit` (and vice versa).

## Moving from Report to Inspection
As of June 23, 2017, we create a 1-1 association between Report and Inspection.
This association means we're carefully setting different data on 2 different models, as can be observed in SpreadsheetParserWorker:

https://github.com/socialappslab/denguetorpedo/blob/d3eb4573b8eaf869c75b10dff639d14e624ce6c7/app/workers/spreadsheet_parsing_worker.rb#L105-L149

To simplify this and accelerate development, I propose we deprecate Report model
in favor of Inspection. To achieve this, I propose we migrate the columns on Report to Inspection, and


## CSV Import
There are 2 ways to import CSV files: one-by-one or batch. I discuss each in turn. The format of CSV should be the following: `/assets/forma_csv.xlsx`.

The general process is:
1. Upload one or more CSV,
2. Create instance of `Spreadsheet`,
2. SpreadsheetParsingWorker parses the CSV and creates `Inspection` and (maybe) `Visit` instances,
4. Updates `parsed_at` column of `Spreadsheet` instance.

### One-by-one
The functionality for one-by-one is located at `http://localhost:5000/csv_reports/new`. The view is managed by `csv_reports/new` and the controller is located at `api/v0/csv_reports_controller.rb`.

The controller really just does the formality of creating the Spreadsheet instance. It then hands the work off to `SpreadsheetParsingWorker.perform_async(@csv_report.id)`, which will be discussed below.

### Batch
The functionality for batch is located at `http://localhost:5000/csv_reports/batch`. The view is managed by `csv_reports/batch` and the controller is located `api/v0/csv_reports_controller.rb`.

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
``

If it doesn't exist, then a new `Inspection` instance is created with that field identifier!

NOTE: To understand how an `Inspection` differs from a `Visit`, I recommend reading the top-level comment in `inspection.rb` model.
