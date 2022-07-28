from std/strformat import fmt
from std/strutils import join
from std/os import createDir, `/`, sleep, fileExists
from std/json import parseJson, items, `{}`, getStr, hasKey, `$`
import std/osproc

proc downloadFile(url, dest: string) =
  if fileExists dest:
    echo "Skipping, file exists."
    return

  let cmd = fmt"""wget "{url}" -O "{dest}_tmp" && mv "{dest}_tmp" "{dest}" """
  # let cmd = fmt"""echo 'wget "{url}" -O "{dest}" '"""
  echo cmd
  let down = startProcess(
    cmd,
    options = {poStdErrToStdOut, poUsePath, poEvalCommand, poDaemon}
  )
  echo down.readLines[0].join "\l"
  close down
    

proc kiwifyDownload*(jsonPath, output: string) =
  ## Downloads using wget all videos of Kiwify course
  let
    json = readFile jsonPath
    node = parseJson json

  createDir output

  writeFile(output / "course.json", json)

  var m = 0
  for module in node{"course", "modules"}:
    let
      moduleName = fmt"{m}_" & module{"name"}.getStr
      modulePath = output / moduleName
    createDir modulePath
    writeFile(modulePath / "module.json", $module)
    echo "Module '", moduleName, "'"
    var l = 0
    for lesson in module{"lessons"}:
      let
        lessonName = fmt"{l}_" & lesson{"title"}.getStr
        lessonPath = modulePath / lessonName
      createDir lessonPath
      writeFile(lessonPath / "lesson.json", $lesson)
      if lesson.hasKey "video":
        echo "  Starting download of '", lessonName, "' video and thumbnail"
        downloadFile(lesson{"video", "download_link"}.getStr, lessonPath / lesson{"video", "name"}.getStr)
        let thumb = lesson{"video", "thumbnail"}.getStr
        if thumb.len > 0:
          downloadFile(thumb, lessonPath / "thumbnail.png")
      else:
        writeFile(lessonPath / "content.html", lesson{"content"}.getStr)

      inc l
    inc m

when isMainModule:
  import pkg/cligen
  dispatch kiwifyDownload
