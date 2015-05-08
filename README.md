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
(the section below is under update, email @animeshpathak or @dman7 if you are having problems)

We strongly recommend Mac OS X or GNU/Linux (the below has been tested with XUbuntu) as your development environment.

After `git clone` or `git checkout`, you need to do the following:
* `bundle install`
* `bundle exec rake db:migrate`
* `bundle exec rake db:development:prepare`
* `bundle exec foreman start`


## Database Architecture
Conceptually, a `Visit` instance to some `Location` instance will generate many breeding site `Report`s. A `Report` instance defines the evolution of a breeding site and so will change over several `Visit`s. The `Inspection` instance defines the state of the breeding site at any given time by associating the `Report` with a `Visit` (and vice versa).
