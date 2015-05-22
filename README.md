**Update: The Datastore API has been deprecated. [Learn more.](https://blogs.dropbox.com/developers/2015/04/deprecating-the-sync-and-datastore-apis/)**

# Lists

This app demonstrates the [Dropbox Datastore API](https://www.dropbox.com/developers/datastore), in particular the use of datastore sharing to support collaboration. You can try the app at [dslists.site44.com](https://dslists.site44.com).

Read more about Lists on the [Dropbox Developers Blog](https://www.dropbox.com/developers/blog/108/new-lists-sample-app).

## Understanding the data model

The Lists app lets you create multiple lists, add items to those lists, and share those lists with other users.

* Each list is a datastore.
* Each datastore contains an "items" table.
* Each record in the "items" table has the following fields:
  * "text": The text of the item.
  * "date": When the item was created (used for sorting).

## Sharing a datastore

When sharing a datastore, the user needs to set the role for one or more principal. For example, the user might set the "public" role to "viewer" to allow viewing but not editing of the list. To learn more about the datastore sharing model, see the [Datastore API HTTP documentation](https://www.dropbox.com/developers/datastore/docs/http#general).

Once a role has been set to allow other users to view or edit a datastore, the datastore may be shared via a URL (`dslists.site44.com#<datastore ID>`) in an email or text message.

If the URL is opened on an iOS device, the user will be prompted to open the datastore in the iOS app. The iOS app uses a custom URL scheme (`Lists://<datastore ID>`) to open the app to the correct list.

### All versions

* [JavaScript](https://github.com/dropbox/lists-js)
* iOS: [Obj-C](https://github.com/dropbox/lists-ios) and [Swift](https://github.com/dropbox/lists-swift)
* [Android] (https://github.com/dropbox/lists-android)
