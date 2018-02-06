# auter-manager

This repo contains ansible playbooks to install and configure Auter on RHEL-derivative devices through automation.

The playbooks operate as follows:

- `auter_install.yml` will install and configure Auter based on settings contained in a CSV file having the following fields:

| name | excludes | AUTOREBOOT | PACKAGEMANAGEROPTIONS | MAXDELAY | INSTALLFROMPREPONLY | PREPTIME | PREPDAY | PREPMONTH | APPLYTIME | APPLYDAY | APPLYMONTH |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| labtest1 |  | yes |  | 300 | yes | 01:00 | 1 | 1-11 | 00:10 | monday:second | 1-11 |
| labtest2 |  | yes |  | 300 | yes | 01:00 | 1 |  | 00:10 | monday:second |   |
| labtest3 |  | no |  | 300 | no | 01:00 | 15 | "1,3,5,7,9,11" | 00:10 | monday:second | "2,4,6,8,10,12" |

By default it will also call playbook `auter_scheduler` after installation, so that your Auter set-up can be fully achieve within one deployment.

Using the csv file should make it easy to keep configuration reference easily readable from a spreadsheet editor. 
**note:** you should not add/remove any columns or the playbook execution will break. The csv file should suffice as the only source for Auter installation / configuration / scheduling.

- `auter_scheduler.yml` on its own handles the crontab configuration for the two main fonctions of Auter: prep and apply. The play will write the cron scheduling into file **/etc/cron.d/auter**

- `auter_reporter.yml` is an easy way to gather information on Auter status and latest use for any number of devices. The result file will be place into directory **auter-manger/output**.

