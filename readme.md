# Kiwify Download

Downloads the kiwify videos from course JSON

The downloaded course will be like:
```
output
     ├ course.json
     ├ Module 1
     │        ├ module.json
     │        ├ Lesson 1
     │        │        ├ video_name.mp4
     │        │        ├ lesson.json
     │        │        └ thumbnail.png*
     │        └ Lesson 2
     │                 ├ video_name.mp4
     │                 ├ lesson.json
     │                 └ thumbnail.png*
     └ Module 2
              ├ module.json
              ├ Lesson 1
              │        ├ video_name.mp4
              │        ├ lesson.json
              │        └ thumbnail.png*
              └ Lesson 2
                       ├ video_name.mp4
                       ├ lesson.json
                       └ thumbnail.png*
[...]
```
*: Downloads if exists

## TODO

- [x] Download embed files in course
- [ ] Get the courses JSON file automatically by using the cookie

## License

MIT
