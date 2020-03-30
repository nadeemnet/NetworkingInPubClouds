# Extending on-prem data center to AWS cloud

## INTRODUCTION

This project is about a medium size enterprise that operates an on-prem data center. There are about 500 employees working in the same location. The IT team manages campus switching/routing as well as data center. Most of the business applications are running from the data center, and IT team is responsible for all maintenance including patching, licensing, software upgrades as well as hardware refreshes.


## ON-PREM DATA CENTER DETAILS

* Total number of rakcs: 8
* Each rack has two ToR switches, whereas the last two racks have core switches
* VMware/vSphere is used where possible for compute virtualization
* There are however some bare-metal servers as well.
* Business applications include MS Exchange, Sharepoint, Web servers and different databases.


For the next HW refresh cycle for MS Exchange and Sharepoint, IT management has decided to use office365 cloud offering. Different application teams have been asking to use cloud based compute and storage services for their needs. IT management has asked to explore public cloud offerings with the following requirements.

## PUBLIC CLOUD REQUIREMENTS

* Compute options should meet diverse memory and cpu requirements
* Compute options should serve elastic demands of the business
* Different storage tiers should be available as per business needs.
* Traffic between existing data center and cloud should be encrypted
* Roles based access should be available for different business units
* Cloud offering should incorporate Infrastructure as code principles.
* Resource usage cost should be available in near real time.
* Traffic into and out of cloud should be controlled
* Cloud should provide DHCP and DNS services
* Cloud should offer different segments with the ability to isolate from each other.
* Hosts in the cloud should have connectivity to data center as well as Internet (local breakout)
* Cloud should offer stateful firewall services
* Cloud should offer audit-trail of the activities performed.
* Cloud should offer presence in different geographical areas.

After studying the major public cloud offerings,  AWS was selected because of its global reach, solution maturity and community following.  










