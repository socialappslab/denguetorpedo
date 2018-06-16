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


## Accessing DengueChat
1. Navigate to http://149.165.156.246:9002/#/containers
2. Ask Cristhian for creds
3. Click Containers > denguetorpedo > console > Connect
4. cd home/dengue/denguetorpedo
