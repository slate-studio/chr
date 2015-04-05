# Character

## Bootstrap Data

Bootstrapped data configuration example with disabled item updates and pagination:

```coffee
postsConfig = (data) ->
  itemTitleField:     'title'
  disableUpdateItems: true
  objects:            data.posts
  arrayStore: new MongosteenArrayStore({
    resource:    'post'
    path:        '/admin/posts'
    sortBy:      'title'
    pagination:  false
  })
  formSchema:
    title: { type: 'string' }
    body:  { type: 'text'   }
```

```disableUpdateItems``` — do not update items in the list while navigation, ```objects``` — provides initial (bootstrapped) array of objects to be added to the list, ```pagination``` — disable pagination for list. If attached as modules root list, you can access store data with: ```chr.modules.posts.arrayStore.data()```.