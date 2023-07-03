from std/strformat import fmt
from std/strutils import join, parseInt, strip, AllChars, Digits
from std/os import createDir, `/`, fileExists
from std/json import parseJson, items, `{}`, getStr, hasKey, `$`
import std/osproc

from pkg/util/forTerm import echoSingleLine
from pkg/util/forFs import escapeFs

proc downloadFile(url, dest: string): bool =
  result = true
  if fileExists dest:
    echo "    Skipping, file exists."
    return false
  let
    u = url
    cmd = fmt"""wget "{u}" -O "{dest}_tmp" && mv "{dest}_tmp" "{dest}" """
    down = startProcess(
      cmd,
      options = {poStdErrToStdOut, poUsePath, poEvalCommand, poDaemon}
    )
  for line in down.lines:
    echoSingleLine line
  echo ""
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
      moduleName = escapeFs(fmt"{m}_" & module{"name"}.getStr)
      modulePath = output / moduleName
    createDir modulePath
    writeFile(modulePath / "module.json", $module)
    echo "\lModule '", moduleName, "'"
    var l = 0
    for lesson in module{"lessons"}:
      let
        lessonName = escapeFs(fmt"{l}_" & lesson{"title"}.getStr)
        lessonPath = modulePath / lessonName
      createDir lessonPath
      writeFile(lessonPath / "lesson.json", $lesson)
      if lesson.hasKey "video":
        echo "  Starting download of '", lessonName, "' video and thumbnail"
        let ok = downloadFile(lesson{"video", "download_link"}.getStr, lessonPath / lesson{"video", "name"}.getStr)
        let thumb = lesson{"video", "thumbnail"}.getStr
        if ok and thumb.len > 0:
          discard downloadFile(thumb, lessonPath / "thumbnail.png")
      elif lesson.hasKey "files":
        echo "  Starting download of '", lessonName, "' files"
        for f in lesson{"files"}:
          discard downloadFile(f{"url"}.getStr, lessonPath / f{"name"}.getStr)
      else:
        writeFile(lessonPath / "content.html", lesson{"content"}.getStr)

      inc l
    inc m

when isMainModule:
  import pkg/cligen
  dispatch kiwifyDownload
