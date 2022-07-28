from std/strformat import fmt
from std/strutils import join
from std/os import createDir, `/`, sleep, fileExists
from std/json import parseJson, items, `{}`, getStr, hasKey, `$`
import std/osproc

var bgDowns: seq[Process]

proc downloadFile(url, dest: string; threads = 3) =
  if fileExists dest:
    echo "Skipping, file exists."
    return
  proc cleanRan =
    for i in countdown(bgDowns.len - 1, 0):
      let bgDown = bgDowns[i]
      if not bgDown.running:
        echo bgDown.readLines[0].join "\l"
        close bgDown
        bgDowns.delete i
  cleanRan()
  if bgDowns.len >= threads:
    while bgDowns.len >= threads:
      cleanRan()
      sleep 200

  let cmd = fmt"""wget "{url}" -O "{dest}" """
  # let cmd = fmt"""echo 'wget "{url}" -O "{dest}" '"""
  echo cmd
  bgDowns.add startProcess(
    cmd,
    options = {poStdErrToStdOut, poUsePath, poEvalCommand, poDaemon}
  )

proc kiwifyDownload*(jsonPath, output: string; threads = 3) =
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
        downloadFile(lesson{"video", "download_link"}.getStr, lessonPath / lesson{"video", "name"}.getStr, threads)
        let thumb = lesson{"video", "thumbnail"}.getStr
        if thumb.len > 0:
          downloadFile(thumb, lessonPath / "thumbnail.png", threads)
      else:
        writeFile(lessonPath / "content.html", lesson{"content"}.getStr)

      inc l
    inc m

when isMainModule:
  import pkg/cligen
  dispatch kiwifyDownload
