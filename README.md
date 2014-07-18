== Dengue Torpedo

Dengue Torpedo is a rails application that tries to solve public health problems by engaging citizens to report
public health risks by mobile phones and gaming tactics.

== SMS
We're using a custom gateway hosted on an Android phone with a custom Android app
written on it. The app essentially waits for incoming texts, and relays them to
our (Rails) app server through a POST request to /reports/gateway.

As of 2014-07-18, this setup is only deployed in Rio de Janeiro, Brazil.

=== Videos
We're keeping a visual history of denguetorpedo.com by taking video snapshots
of specific pages. These videos are compressed as .swf files in `/videos`
directory.
