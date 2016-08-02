# Web App Design

**NOTE: This design document is written for the development team only. The
team may amend the design decisions outlined and this document and is free
to leave the document un-updated with such changes. This document is meant
to describe how the software should be built, but is NOT indicative of how
it was actually built.**

# Purpose

Provide the wonderful means to query the RT ticket database. At this point in
time, there are no plans to make the software to be a complete interface with
the rt.perl.org system—that is the system is meant to provide read-only
access to RT.

# API

The web app must provide two interfaces:

* Normal HTML view for humans to use
* JSON API for IRC bots (and other ilk) to use

## Features

The API must provide the following features:

* Display ticket tag statistics
* Display number of tickets tagged with a particular set of tags
* Perform full-text (including ticket body and comments) search, optionally
providing extra search operators, regex, or search by subject only
* Viewing all tickets (id, tags, subject only) on a single page, while making
it easy to view ticket body (e.g. loading extra content via an
async JS request)
* Easily accessing RT interface. *This step is currently optional due to
possible limitations due to RT's CSRF protection*

## Web

The Web interface is to consist of a table with ticket ids, tags, and subjects,
providing a means to view full ticket body and its comments.

At the top of the page a search box will be located. Typing in the search
box will filter the shown list of tickets by subject line. But clicking the
"full text search" button will perform a search on ticket bodies and comments
as well.

Also at the top of the page is to be a set of buttons named after currently
available tags. Clicking one of the buttons will filter the displayed list
by that tag.

All of the described interface must be linkable; that is, it must be
possible to link to only to a set of tickets tagged with a specific tag or
to a specific full-text search.

## JSON

The JSON API has to provide the same features as the Web interface.

